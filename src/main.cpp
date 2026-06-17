#include "GoogleAuth.h"
#include "GmailService.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QObject>
#include <QSurfaceFormat>
#include <stdio.h>

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");

    QSurfaceFormat fmt;
    fmt.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(fmt);

    QGuiApplication app(argc, argv);
    app.setOrganizationName("bounce");
    app.setApplicationName("bounce");

    QQmlApplicationEngine engine;

    auto *auth  = new GoogleAuth(&app);
    auto *gmail = new GmailService(auth, &app);
    qmlRegisterSingletonInstance("Bounce.Auth", 1, 0, "GoogleAuth",   auth);
    qmlRegisterSingletonInstance("Bounce.Mail", 1, 0, "GmailService", gmail);

    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        for (const QQmlError &w : warnings)
            fprintf(stderr, "QML warn: %s\n", qPrintable(w.toString()));
    });
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     [](const QUrl &url) {
        fprintf(stderr, "QML load FAILED: %s\n", qPrintable(url.toString()));
    });

    engine.addImportPath(QStringLiteral("qrc:/qml"));
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        fprintf(stderr, "engine.rootObjects() is empty — load failed.\n");
        return 1;
    }
    return app.exec();
}
