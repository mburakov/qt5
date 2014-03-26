/****************************************************************************
**
** Copyright (C) 2012 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the QtMacExtras module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QMACTOOLBAR_H
#define QMACTOOLBAR_H

#include "qmacextrasglobal.h"
#include "qmactoolbutton_p.h"

#include <QtCore/QString>
#include <QtCore/QObject>
#include <QtCore/QVariant>
#include <QtGui/QIcon>

Q_FORWARD_DECLARE_OBJC_CLASS(NSToolbar);

QT_BEGIN_NAMESPACE

class QWindow;
class QMacNativeToolBar;
class QMacNativeToolBarPrivate;

class Q_MACEXTRAS_EXPORT QMacNativeToolBar : public QObject
{
    friend class QMacNativeToolBarPrivate;

    Q_OBJECT
    Q_PROPERTY(QList<QMacToolButton *> buttons READ buttons)
    Q_PROPERTY(QList<QMacToolButton *> allowedButtons READ allowedButtons)
public:
    QMacNativeToolBar(QObject *parent = 0);
    QMacNativeToolBar(const QString &identifier, QObject *parent = 0);
    ~QMacNativeToolBar();

    NSToolbar* nativeToolbar() const;

    QString identifier() const;
    bool isVisible() const;
    bool showsBaselineSeparator() const;
    bool allowsUserCustomization() const;
    Qt::ToolButtonStyle toolButtonStyle() const;
    QSize iconSize() const;
    QMacToolButton::IconSize iconSizeType() const;

    QList<QMacToolButton *> buttons();
    QList<QMacToolButton *> allowedButtons();

    void showInWindow(QWindow *window);

    void removeFromWindow(QWindow *window);

    // Add actions to the toolbar
    Q_INVOKABLE QMacToolButton *addAction(const QString &text);
    Q_INVOKABLE QMacToolButton *addAction(const QIcon &icon, const QString &text);
    Q_INVOKABLE void addSeparator();
    Q_INVOKABLE QMacToolButton *addStandardItem(QMacToolButton::StandardItem standardItem);

    // Add actions to the "Customize Toolbar" menu
    Q_INVOKABLE QMacToolButton *addAllowedAction(const QString &text);
    Q_INVOKABLE QMacToolButton *addAllowedAction(const QIcon &icon, const QString &text);
    Q_INVOKABLE QMacToolButton *addAllowedStandardItem(QMacToolButton::StandardItem standardItem);

Q_SIGNALS:
    void visibilityChanged(bool visible);
    void showsBaselineSeparatorChanged(bool show);
    void allowsUserCustomizationChanged(bool allow);
    void toolButtonStyleChanged(Qt::ToolButtonStyle toolButtonStyle);
    void iconSizeChanged(const QSize &iconSize);
    void iconSizeChanged(QMacToolButton::IconSize iconSize);

public Q_SLOTS:
    void setVisible(bool visible);
    void setShowsBaselineSeparator(bool show);
    void setAllowsUserCustomization(bool allow);
    void setToolButtonStyle(Qt::ToolButtonStyle toolButtonStyle);
    void setIconSize(const QSize &iconSize);
    void setIconSize(QMacToolButton::IconSize iconSize);
    void showCustomizationSheet();

private Q_SLOTS:
    void showInWindow_impl();
    void setSelectedItem();
//### TODO- re-implement
#if 0
    QMacToolButton *setSelectedItem(QMacToolbarAction *action);
    void checkSelectableItemSanity();
#endif
private:
    QWindow *targetWindow;
    void *targetWidget;
    QList<QMacToolButton *> m_buttons;
    QList<QMacToolButton *> m_allowedButtons;
    QMacNativeToolBarPrivate *d;
};

QT_END_NAMESPACE

Q_DECLARE_METATYPE(QMacNativeToolBar*)

#endif

