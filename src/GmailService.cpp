#include "GmailService.h"
#include "GoogleAuth.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QUrl>
#include <QUrlQuery>

static const char *kListUrl    = "https://gmail.googleapis.com/gmail/v1/users/me/messages";
static const char *kMsgUrl     = "https://gmail.googleapis.com/gmail/v1/users/me/messages/";
static const char *kThreadUrl  = "https://gmail.googleapis.com/gmail/v1/users/me/threads/";

// ---- helpers ----------------------------------------------------------------

static QString computeInitials(const QString &name)
{
    const auto parts = name.split(QChar(' '), Qt::SkipEmptyParts);
    if (parts.isEmpty()) return QStringLiteral("??");
    if (parts.size() == 1) {
        const auto &p = parts.first();
        return (p.left(1) + (p.size() > 1 ? p.mid(1, 1) : QString())).toUpper();
    }
    return (parts.first().left(1) + parts.last().left(1)).toUpper();
}

static int hashToPalette(const QString &key)
{
    return static_cast<int>(qHash(key) % 6u);
}

static QString formatTime(const QDateTime &dt)
{
    const auto local = dt.toLocalTime();
    const auto today = QDate::currentDate();
    const auto date  = local.date();
    if (date == today)              return local.toString(QStringLiteral("h:mm AP"));
    if (date == today.addDays(-1))  return QStringLiteral("Yesterday");
    if (date >= today.addDays(-6))  return local.toString(QStringLiteral("ddd"));
    return local.toString(QStringLiteral("d MMM"));
}

// Walk a payload tree looking for the first part whose mimeType starts with
// `wantedMime`. Returns the decoded body or empty string.
static QString findBodyByMime(const QJsonObject &payload, const QString &wantedMime)
{
    const QString mimeType = payload.value(QStringLiteral("mimeType")).toString();
    if (mimeType.startsWith(wantedMime, Qt::CaseInsensitive)) {
        const QString data = payload.value(QStringLiteral("body"))
                                    .toObject()
                                    .value(QStringLiteral("data"))
                                    .toString();
        if (!data.isEmpty()) {
            return QString::fromUtf8(QByteArray::fromBase64(data.toUtf8(),
                QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
        }
    }
    for (const auto &p : payload.value(QStringLiteral("parts")).toArray()) {
        const QString r = findBodyByMime(p.toObject(), wantedMime);
        if (!r.isEmpty()) return r;
    }
    return {};
}

// Prefer text/plain; fall back to a crudely-stripped text/html.
static QString findReadableBody(const QJsonObject &payload)
{
    const QString text = findBodyByMime(payload, QStringLiteral("text/plain"));
    if (!text.isEmpty()) return text;

    QString html = findBodyByMime(payload, QStringLiteral("text/html"));
    if (html.isEmpty()) return {};

    static const QRegularExpression tagRe(QStringLiteral("<[^>]+>"));
    html.remove(tagRe);
    html.replace(QStringLiteral("&nbsp;"), QStringLiteral(" "));
    html.replace(QStringLiteral("&amp;"),  QStringLiteral("&"));
    html.replace(QStringLiteral("&lt;"),   QStringLiteral("<"));
    html.replace(QStringLiteral("&gt;"),   QStringLiteral(">"));
    html.replace(QStringLiteral("&quot;"), QStringLiteral("\""));
    html.replace(QStringLiteral("&#39;"),  QStringLiteral("'"));
    return html;
}

static QPair<QString, QString> parseFrom(const QString &from)
{
    // "Name <email>" → (Name, email). If no angle brackets, the whole
    // string is treated as both fields.
    static const QRegularExpression re(QStringLiteral("^\"?([^\"<]*?)\"?\\s*<([^>]+)>\\s*$"));
    const auto m = re.match(from);
    if (m.hasMatch()) {
        QString name  = m.captured(1).trimmed();
        QString email = m.captured(2).trimmed();
        if (name.isEmpty()) name = email;
        return { name, email };
    }
    return { from, from };
}

// ---- GmailService -----------------------------------------------------------

GmailService::GmailService(GoogleAuth *auth, QObject *parent)
    : QObject(parent), m_auth(auth)
{
    connect(auth, &GoogleAuth::authenticatedChanged, this, [this, auth]() {
        if (auth->authenticated())
            fetchInbox();
        else {
            m_messages.clear();
            emit messagesChanged();
        }
    });
}

void GmailService::fetchInbox()
{
    if (!m_auth || !m_auth->authenticated()) {
        setError(QStringLiteral("Not signed in"));
        return;
    }
    setError(QString());
    setLoading(true);

    m_orderedIds.clear();
    m_collected.clear();
    m_pending = 0;

    QUrl url(QString::fromLatin1(kListUrl));
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("labelIds"),   QStringLiteral("INBOX"));
    q.addQueryItem(QStringLiteral("maxResults"), QStringLiteral("50"));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setRawHeader("Authorization", "Bearer " + m_auth->accessToken().toUtf8());

    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            setError(QStringLiteral("Inbox list failed: ") + reply->errorString());
            setLoading(false);
            return;
        }
        const auto root = QJsonDocument::fromJson(reply->readAll()).object();
        const auto arr  = root.value(QStringLiteral("messages")).toArray();
        if (arr.isEmpty()) {
            m_messages.clear();
            emit messagesChanged();
            setLoading(false);
            return;
        }
        m_pending = arr.size();
        for (const auto &v : arr) {
            const QString id = v.toObject().value(QStringLiteral("id")).toString();
            m_orderedIds.append(id);
            fetchMessageDetail(id);
        }
    });
}

void GmailService::fetchMessageDetail(const QString &id)
{
    QUrl url(QString::fromLatin1(kMsgUrl) + id);
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("format"), QStringLiteral("metadata"));
    q.addQueryItem(QStringLiteral("metadataHeaders"), QStringLiteral("From"));
    q.addQueryItem(QStringLiteral("metadataHeaders"), QStringLiteral("Subject"));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setRawHeader("Authorization", "Bearer " + m_auth->accessToken().toUtf8());

    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, id]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            const auto obj = QJsonDocument::fromJson(reply->readAll()).object();
            m_collected.insert(id, parseMessage(obj));
        } else {
            // Don't bail the whole batch on a single failure.
            qWarning("GmailService: failed to fetch %s: %s",
                     qPrintable(id), qPrintable(reply->errorString()));
        }
        if (--m_pending <= 0) {
            QVariantList out;
            for (const auto &mid : m_orderedIds) {
                if (m_collected.contains(mid))
                    out.append(m_collected.value(mid));
            }
            m_messages = out;
            emit messagesChanged();
            setLoading(false);
        }
    });
}

QVariantMap GmailService::parseMessage(const QJsonObject &m) const
{
    QString from, subject;
    const auto headers = m.value(QStringLiteral("payload"))
                          .toObject()
                          .value(QStringLiteral("headers"))
                          .toArray();
    for (const auto &h : headers) {
        const auto ho = h.toObject();
        const QString name = ho.value(QStringLiteral("name")).toString();
        if      (name.compare(QStringLiteral("From"),    Qt::CaseInsensitive) == 0)
            from = ho.value(QStringLiteral("value")).toString();
        else if (name.compare(QStringLiteral("Subject"), Qt::CaseInsensitive) == 0)
            subject = ho.value(QStringLiteral("value")).toString();
    }
    const auto [fromName, fromEmail] = parseFrom(from);

    bool unread = false, starred = false;
    for (const auto &l : m.value(QStringLiteral("labelIds")).toArray()) {
        const QString id = l.toString();
        if      (id == QStringLiteral("UNREAD"))  unread  = true;
        else if (id == QStringLiteral("STARRED")) starred = true;
    }

    const qint64 internalMs =
        m.value(QStringLiteral("internalDate")).toString().toLongLong();

    QVariantMap row;
    row.insert(QStringLiteral("threadId"), m.value(QStringLiteral("threadId")).toString());
    row.insert(QStringLiteral("from"),     fromName);
    row.insert(QStringLiteral("initials"), computeInitials(fromName));
    row.insert(QStringLiteral("palette"),  hashToPalette(fromEmail));
    row.insert(QStringLiteral("subject"),  subject);
    row.insert(QStringLiteral("snippet"),  m.value(QStringLiteral("snippet")).toString());
    row.insert(QStringLiteral("time"),     formatTime(QDateTime::fromMSecsSinceEpoch(internalMs)));
    row.insert(QStringLiteral("unread"),   unread);
    row.insert(QStringLiteral("starred"),  starred);
    row.insert(QStringLiteral("chips"),    QVariantList{});
    return row;
}

// ---- threads --------------------------------------------------------------

void GmailService::fetchThread(const QString &threadId)
{
    if (!m_auth || !m_auth->authenticated() || threadId.isEmpty()) return;

    setThreadLoading(true);
    m_currentThread.clear();
    emit currentThreadChanged();

    QUrl url(QString::fromLatin1(kThreadUrl) + threadId);
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("format"), QStringLiteral("full"));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setRawHeader("Authorization", "Bearer " + m_auth->accessToken().toUtf8());

    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            setError(QStringLiteral("Thread fetch failed: ") + reply->errorString());
            setThreadLoading(false);
            return;
        }
        const auto root = QJsonDocument::fromJson(reply->readAll()).object();
        const auto arr  = root.value(QStringLiteral("messages")).toArray();

        QVariantList out;
        const int n = arr.size();
        for (int i = 0; i < n; ++i) {
            out.append(parseThreadMessage(arr.at(i).toObject(), i == n - 1));
        }
        m_currentThread = out;
        emit currentThreadChanged();
        setThreadLoading(false);
    });
}

void GmailService::clearThread()
{
    if (m_currentThread.isEmpty() && !m_threadLoading) return;
    m_currentThread.clear();
    emit currentThreadChanged();
    setThreadLoading(false);
}

QVariantMap GmailService::parseThreadMessage(const QJsonObject &m, bool isLast) const
{
    QString from, to;
    const auto headers = m.value(QStringLiteral("payload"))
                          .toObject()
                          .value(QStringLiteral("headers"))
                          .toArray();
    for (const auto &h : headers) {
        const auto ho = h.toObject();
        const QString name = ho.value(QStringLiteral("name")).toString();
        if      (name.compare(QStringLiteral("From"), Qt::CaseInsensitive) == 0)
            from = ho.value(QStringLiteral("value")).toString();
        else if (name.compare(QStringLiteral("To"),   Qt::CaseInsensitive) == 0)
            to   = ho.value(QStringLiteral("value")).toString();
    }
    const auto [fromName, fromEmail] = parseFrom(from);

    const qint64 internalMs =
        m.value(QStringLiteral("internalDate")).toString().toLongLong();

    // Pull both text/plain and text/html. ThreadMessage prefers HTML in the
    // embedded browser; plain is kept as a fallback.
    const auto payload = m.value(QStringLiteral("payload")).toObject();
    const QString htmlBody = findBodyByMime(payload, QStringLiteral("text/html"));
    QString textBody = findBodyByMime(payload, QStringLiteral("text/plain"));
    if (textBody.isEmpty() && !htmlBody.isEmpty()) {
        // Crude fallback for the no-WebEngine path.
        textBody = htmlBody;
        static const QRegularExpression tagRe(QStringLiteral("<[^>]+>"));
        textBody.remove(tagRe);
    }

    static const QRegularExpression paraRe(QStringLiteral("\\r?\\n\\s*\\r?\\n"));
    QVariantList paragraphs;
    for (const auto &p : textBody.split(paraRe, Qt::SkipEmptyParts)) {
        const QString trimmed = p.trimmed();
        if (!trimmed.isEmpty()) paragraphs.append(trimmed);
    }

    QVariantMap row;
    row.insert(QStringLiteral("from"),     fromName);
    row.insert(QStringLiteral("initials"), computeInitials(fromName));
    row.insert(QStringLiteral("palette"),  hashToPalette(fromEmail));
    row.insert(QStringLiteral("to"),       to.isEmpty() ? QString() : QStringLiteral("to ") + to);
    row.insert(QStringLiteral("when"),     formatTime(QDateTime::fromMSecsSinceEpoch(internalMs)));
    row.insert(QStringLiteral("open"),     isLast); // latest message expanded by default
    row.insert(QStringLiteral("preview"),  m.value(QStringLiteral("snippet")).toString());
    row.insert(QStringLiteral("body"),     paragraphs);
    row.insert(QStringLiteral("bodyHtml"), htmlBody);
    return row;
}

void GmailService::setThreadLoading(bool v)
{
    if (m_threadLoading != v) { m_threadLoading = v; emit threadLoadingChanged(); }
}

void GmailService::setLoading(bool v)
{
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void GmailService::setError(const QString &e)
{
    if (m_error != e) { m_error = e; emit errorChanged(); }
}
