#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QOAuth2AuthorizationCodeFlow>

class QOAuthHttpServerReplyHandler;

class GoogleAuth : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool authenticated READ authenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(bool restoring READ restoring NOTIFY restoringChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY userInfoChanged)
    Q_PROPERTY(QString userEmail READ userEmail NOTIFY userInfoChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool configured READ configured CONSTANT)

public:
    explicit GoogleAuth(QObject *parent = nullptr);

    bool authenticated() const { return m_authenticated; }
    bool restoring() const { return m_restoring; }
    QString userName() const { return m_userName; }
    QString userEmail() const { return m_userEmail; }
    QString status() const { return m_status; }
    bool configured() const { return !m_oauth.clientIdentifier().isEmpty(); }

    Q_INVOKABLE void signIn();
    Q_INVOKABLE void signOut();

signals:
    void authenticatedChanged();
    void restoringChanged();
    void userInfoChanged();
    void statusChanged();

private:
    void fetchUserInfo();
    void setStatus(const QString &s);
    void loadRefreshToken();
    void saveRefreshToken(const QString &token);
    void deleteRefreshToken();

    QNetworkAccessManager m_nam;
    QOAuth2AuthorizationCodeFlow m_oauth;
    QOAuthHttpServerReplyHandler *m_handler = nullptr;
    bool m_authenticated = false;
    bool m_restoring = false;
    QString m_userName;
    QString m_userEmail;
    QString m_status;

    void setRestoring(bool v);
};
