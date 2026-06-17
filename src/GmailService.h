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

public:
    explicit GmailService(GoogleAuth *auth, QObject *parent = nullptr);

    QVariantList messages() const { return m_messages; }
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }

    Q_INVOKABLE void fetchInbox();

signals:
    void messagesChanged();
    void loadingChanged();
    void errorChanged();

private:
    void fetchMessageDetail(const QString &id);
    QVariantMap parseMessage(const QJsonObject &m) const;

    void setLoading(bool v);
    void setError(const QString &e);

    GoogleAuth *m_auth = nullptr;
    QNetworkAccessManager m_nam;

    QVariantList m_messages;
    bool m_loading = false;
    QString m_error;

    // In-flight batch state.
    QStringList m_orderedIds;
    QHash<QString, QVariantMap> m_collected;
    int m_pending = 0;
};
