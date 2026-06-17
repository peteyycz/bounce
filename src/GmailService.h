#pragma once

#include <QHash>
#include <QNetworkAccessManager>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class GoogleAuth;
class QNetworkReply;
class QJsonObject;

// Thin Gmail REST client. Pulls the first page of the user's INBOX and
// exposes the rows in the shape MessageRow.qml expects.
class GmailService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList messages READ messages NOTIFY messagesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QVariantList currentThread READ currentThread NOTIFY currentThreadChanged)
    Q_PROPERTY(bool threadLoading READ threadLoading NOTIFY threadLoadingChanged)

public:
    explicit GmailService(GoogleAuth *auth, QObject *parent = nullptr);

    QVariantList messages() const { return m_messages; }
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }
    QVariantList currentThread() const { return m_currentThread; }
    bool threadLoading() const { return m_threadLoading; }

    Q_INVOKABLE void fetchInbox();
    Q_INVOKABLE void fetchThread(const QString &threadId);
    Q_INVOKABLE void clearThread();

signals:
    void messagesChanged();
    void loadingChanged();
    void errorChanged();
    void currentThreadChanged();
    void threadLoadingChanged();

private:
    void fetchMessageDetail(const QString &id);
    QVariantMap parseMessage(const QJsonObject &m) const;
    QVariantMap parseThreadMessage(const QJsonObject &m, bool isLast) const;

    void setLoading(bool v);
    void setError(const QString &e);
    void setThreadLoading(bool v);

    GoogleAuth *m_auth = nullptr;
    QNetworkAccessManager m_nam;

    QVariantList m_messages;
    bool m_loading = false;
    QString m_error;

    QVariantList m_currentThread;
    bool m_threadLoading = false;

    // In-flight batch state for the inbox list.
    QStringList m_orderedIds;
    QHash<QString, QVariantMap> m_collected;
    int m_pending = 0;
};
