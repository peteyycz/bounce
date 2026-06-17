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

static const char *kListUrl = "https://gmail.googleapis.com/gmail/v1/users/me/messages";
static const char *kMsgUrl  = "https://gmail.googleapis.com/gmail/v1/users/me/messages/";

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

void GmailService::setLoading(bool v)
{
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void GmailService::setError(const QString &e)
{
    if (m_error != e) { m_error = e; emit errorChanged(); }
}
