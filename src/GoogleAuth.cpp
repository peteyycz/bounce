#include "GoogleAuth.h"
#include "Credentials.h"

#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QOAuthHttpServerReplyHandler>
#include <QUrl>
#include <qt6keychain/keychain.h>

using QKeychain::DeletePasswordJob;
using QKeychain::ReadPasswordJob;
using QKeychain::WritePasswordJob;

static const QString kKeychainService = QStringLiteral("bounce");
static const QString kRefreshTokenKey = QStringLiteral("google_refresh_token");

// Endpoints — public, never change for Google OAuth 2.
static const char *kAuthUrl     = "https://accounts.google.com/o/oauth2/v2/auth";
static const char *kTokenUrl    = "https://oauth2.googleapis.com/token";
static const char *kUserInfoUrl = "https://openidconnect.googleapis.com/v1/userinfo";

// Minimum scopes to identify the user. Gmail scopes get added when we
// wire actual mail loading.
static const char *kScope = "openid email profile";

GoogleAuth::GoogleAuth(QObject *parent) : QObject(parent)
{
    const QLatin1String clientId(BOUNCE_OAUTH_CLIENT_ID);
    const QLatin1String clientSecret(BOUNCE_OAUTH_CLIENT_SECRET);

    if (clientId.size() == 0 || clientSecret.size() == 0) {
        m_status = "No credentials baked in (reconfigure with "
                   "-DBOUNCE_CREDENTIALS_FILE=...)";
        // restoring stays false — there's nothing to restore.
        return;
    }

    m_oauth.setAuthorizationUrl(QUrl(QString::fromLatin1(kAuthUrl)));
    m_oauth.setTokenUrl(QUrl(QString::fromLatin1(kTokenUrl)));
    m_oauth.setClientIdentifier(clientId);
    m_oauth.setClientIdentifierSharedKey(clientSecret);
    m_oauth.setRequestedScopeTokens({ QByteArray("openid"),
                                      QByteArray("email"),
                                      QByteArray("profile") });

    // PKCE — required for installed apps per RFC 8252.
    m_oauth.setPkceMethod(QOAuth2AuthorizationCodeFlow::PkceMethod::S256);

    // port 0 → OS picks a free port for the loopback redirect.
    m_handler = new QOAuthHttpServerReplyHandler(0, this);
    m_oauth.setReplyHandler(m_handler);

    connect(&m_oauth, &QOAuth2AuthorizationCodeFlow::authorizeWithBrowser,
            this, [](const QUrl &url) {
        QDesktopServices::openUrl(url);
    });

    connect(&m_oauth, &QOAuth2AuthorizationCodeFlow::granted, this, [this]() {
        m_authenticated = true;
        emit authenticatedChanged();
        setStatus("Signed in");
        setRestoring(false);
        fetchUserInfo();
        saveRefreshToken(m_oauth.refreshToken());
    });

    connect(&m_oauth, &QAbstractOAuth::requestFailed, this,
            [this](QAbstractOAuth::Error error) {
        setStatus("OAuth failed: error " + QString::number(static_cast<int>(error)));
        setRestoring(false);
    });

    // Try to restore a previous session from the keychain.
    setRestoring(true);
    loadRefreshToken();
}

void GoogleAuth::setRestoring(bool v)
{
    if (m_restoring != v) {
        m_restoring = v;
        emit restoringChanged();
    }
}

void GoogleAuth::loadRefreshToken()
{
    auto *job = new ReadPasswordJob(kKeychainService, this);
    job->setKey(kRefreshTokenKey);
    connect(job, &QKeychain::Job::finished, this, [this, job]() {
        job->deleteLater();
        if (job->error() == QKeychain::EntryNotFound) {
            setRestoring(false);
            return; // nothing stored — fall back to interactive sign-in
        }
        if (job->error() != QKeychain::NoError) {
            setStatus("Keychain read failed: " + job->errorString());
            setRestoring(false);
            return;
        }
        const QString token = job->textData();
        if (token.isEmpty()) {
            setRestoring(false);
            return;
        }

        m_oauth.setRefreshToken(token);
        setStatus("Restoring session…");
        m_oauth.refreshTokens();
    });
    job->start();
}

void GoogleAuth::saveRefreshToken(const QString &token)
{
    if (token.isEmpty()) return;
    auto *job = new WritePasswordJob(kKeychainService, this);
    job->setKey(kRefreshTokenKey);
    job->setTextData(token);
    connect(job, &QKeychain::Job::finished, this, [this, job]() {
        job->deleteLater();
        if (job->error() != QKeychain::NoError)
            setStatus("Keychain save failed: " + job->errorString());
    });
    job->start();
}

void GoogleAuth::deleteRefreshToken()
{
    auto *job = new DeletePasswordJob(kKeychainService, this);
    job->setKey(kRefreshTokenKey);
    connect(job, &QKeychain::Job::finished, this, [job]() { job->deleteLater(); });
    job->start();
}

void GoogleAuth::signIn()
{
    if (!configured()) {
        setStatus("OAuth not configured");
        return;
    }
    setStatus("Opening browser…");
    m_oauth.grant();
}

void GoogleAuth::signOut()
{
    deleteRefreshToken();
    m_authenticated = false;
    m_userName.clear();
    m_userEmail.clear();
    emit authenticatedChanged();
    emit userInfoChanged();
    setStatus("");
}

void GoogleAuth::fetchUserInfo()
{
    QNetworkRequest req((QUrl(QString::fromLatin1(kUserInfoUrl))));
    req.setRawHeader("Authorization", "Bearer " + m_oauth.token().toUtf8());

    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            setStatus("userinfo failed: " + reply->errorString());
            return;
        }
        const auto obj = QJsonDocument::fromJson(reply->readAll()).object();
        m_userName  = obj.value("name").toString();
        m_userEmail = obj.value("email").toString();
        emit userInfoChanged();
    });
}

void GoogleAuth::setStatus(const QString &s)
{
    if (m_status != s) {
        m_status = s;
        emit statusChanged();
    }
}
