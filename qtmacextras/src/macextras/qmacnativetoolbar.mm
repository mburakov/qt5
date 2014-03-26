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
#import <AppKit/AppKit.h>
#include "qmacnativetoolbar_p.h"

#include <QtGui/QGuiApplication>
#include <QtCore/QDebug>
#include <QtCore/QTimer>
#include <QtCore/QUuid>

#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
#include <QtGui/QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#else
#include <QtGui/QMainWindow>
#endif

#include "qmacfunctions.h"
#include "qmacfunctions_p.h"
#include "qmactoolbardelegate_p.h"
#include "qnstoolbar_p.h"

// from the Apple NSToolbar documentation
#define kNSToolbarIconSizeSmall 24
#define kNSToolbarIconSizeRegular 32
#define kNSToolbarIconSizeDefault kNSToolbarIconSizeRegular

NSString *toNSStandardItem(QMacToolButton::StandardItem standardItem)
{
    if (standardItem == QMacToolButton::ShowColors)
        return NSToolbarShowColorsItemIdentifier;
    else if (standardItem == QMacToolButton::ShowFonts)
        return NSToolbarShowFontsItemIdentifier;
    else if (standardItem == QMacToolButton::PrintItem)
        return NSToolbarPrintItemIdentifier;
    else if (standardItem == QMacToolButton::Space)
        return NSToolbarSpaceItemIdentifier;
    else if (standardItem == QMacToolButton::FlexibleSpace)
        return NSToolbarFlexibleSpaceItemIdentifier;
    return @"";
}

QT_BEGIN_NAMESPACE

NSToolbarDisplayMode toNSToolbarDisplayMode(Qt::ToolButtonStyle toolButtonStyle)
{
    switch (toolButtonStyle)
    {
    case Qt::ToolButtonIconOnly:
        return NSToolbarDisplayModeIconOnly;
    case Qt::ToolButtonTextOnly:
        return NSToolbarDisplayModeLabelOnly;
    case Qt::ToolButtonTextBesideIcon:
    case Qt::ToolButtonTextUnderIcon:
        return NSToolbarDisplayModeIconAndLabel;
    case Qt::ToolButtonFollowStyle:
    default:
        return NSToolbarDisplayModeDefault;
    }
}

Qt::ToolButtonStyle toQtToolButtonStyle(NSToolbarDisplayMode toolbarDisplayMode)
{
    switch (toolbarDisplayMode)
    {
    case NSToolbarDisplayModeIconAndLabel:
        return Qt::ToolButtonTextUnderIcon;
    case NSToolbarDisplayModeIconOnly:
        return Qt::ToolButtonIconOnly;
    case NSToolbarDisplayModeLabelOnly:
        return Qt::ToolButtonTextOnly;
    case NSToolbarDisplayModeDefault:
    default:
        return Qt::ToolButtonFollowStyle;
    }
}

QT_END_NAMESPACE

#include <qglobal.h>

@interface QT_MANGLE_NAMESPACE(QNSToolbarNotifier) : NSObject
{
@public
    QMacNativeToolBarPrivate *pimpl;
}
- (void)notification:(NSNotification*)note;
@end

QT_NAMESPACE_ALIAS_OBJC_CLASS(QNSToolbarNotifier);

QT_BEGIN_NAMESPACE

class QMacNativeToolBarPrivate
{
public:
    QMacNativeToolBar *qtToolbar;
    QtNSToolbar *toolbar;
    QMacToolbarDelegate *delegate;
    QNSToolbarNotifier *notifier;

    QMacNativeToolBarPrivate(QMacNativeToolBar *parent, const QString &identifier = QString())
    {
        qtToolbar = parent;
        toolbar = [[QtNSToolbar alloc] initWithIdentifier:QtMac::toNSString(identifier.isEmpty() ? QUuid::createUuid().toString() : identifier)];
        [toolbar setAutosavesConfiguration:NO];

        delegate = [[QMacToolbarDelegate alloc] init];
        [toolbar setDelegate:delegate];

        notifier = [[QNSToolbarNotifier alloc] init];
        notifier->pimpl = this;
        [[NSNotificationCenter defaultCenter] addObserver:notifier selector:@selector(notification:) name:nil object:toolbar];
    }

    ~QMacNativeToolBarPrivate()
    {
        [[NSNotificationCenter defaultCenter] removeObserver:notifier name:nil object:toolbar];
    }

    void fireVisibilityChanged()
    {
        Q_ASSERT(qtToolbar);
        Q_EMIT qtToolbar->visibilityChanged(qtToolbar->isVisible());
    }

    void fireShowsBaselineSeparatorChanged()
    {
        Q_ASSERT(qtToolbar);
        Q_EMIT qtToolbar->showsBaselineSeparatorChanged(qtToolbar->showsBaselineSeparator());
    }

    void fireToolButtonStyleChanged()
    {
        Q_ASSERT(qtToolbar);
        Q_EMIT qtToolbar->toolButtonStyleChanged(qtToolbar->toolButtonStyle());
    }

    void fireSizeModeChangedNotification()
    {
        Q_ASSERT(qtToolbar);
        Q_EMIT qtToolbar->iconSizeChanged(qtToolbar->iconSize());
        Q_EMIT qtToolbar->iconSizeChanged(qtToolbar->iconSizeType());
    }

    void fireAllowsUserCustomizationChanged()
    {
        Q_ASSERT(qtToolbar);
        Q_EMIT qtToolbar->allowsUserCustomizationChanged(qtToolbar->allowsUserCustomization());
    }
};

QMacNativeToolBar::QMacNativeToolBar(QObject *parent)
    : QObject(parent), targetWindow(NULL), targetWidget(NULL), d(new QMacNativeToolBarPrivate(this))
{
    setAllowsUserCustomization(true);
    setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
}

QMacNativeToolBar::QMacNativeToolBar(const QString &identifier, QObject *parent)
    : QObject(parent), targetWindow(NULL), targetWidget(NULL), d(new QMacNativeToolBarPrivate(this, identifier))
{
    setAllowsUserCustomization(true);
    setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
}

QMacNativeToolBar::~QMacNativeToolBar()
{
    [d->toolbar release];
    delete d;
}

NSToolbar *QMacNativeToolBar::nativeToolbar() const
{
    return d->toolbar;
}

QString QMacNativeToolBar::identifier() const
{
    return QtMac::fromNSString([d->toolbar identifier]);
}

bool QMacNativeToolBar::isVisible() const
{
    return [d->toolbar isVisible];
}

void QMacNativeToolBar::setVisible(bool visible)
{
    [d->toolbar setVisible:visible];
}

bool QMacNativeToolBar::showsBaselineSeparator() const
{
    return [d->toolbar showsBaselineSeparator];
}

void QMacNativeToolBar::setShowsBaselineSeparator(bool show)
{
    [d->toolbar setShowsBaselineSeparator:show];
}

bool QMacNativeToolBar::allowsUserCustomization() const
{
    return [d->toolbar allowsUserCustomization];
}

void QMacNativeToolBar::setAllowsUserCustomization(bool allow)
{
    [d->toolbar setAllowsUserCustomization:allow];
}

Qt::ToolButtonStyle QMacNativeToolBar::toolButtonStyle() const
{
    return toQtToolButtonStyle([d->toolbar displayMode]);
}

void QMacNativeToolBar::setToolButtonStyle(Qt::ToolButtonStyle toolButtonStyle)
{
    [d->toolbar setDisplayMode:toNSToolbarDisplayMode(toolButtonStyle)];

    // Since this isn't supported, no change event will be fired so do it manually
    if (toolButtonStyle == Qt::ToolButtonTextBesideIcon)
        d->fireToolButtonStyleChanged();
}

QSize QMacNativeToolBar::iconSize() const
{
    switch (iconSizeType())
    {
    case QMacToolButton::IconSizeRegular:
        return QSize(kNSToolbarIconSizeRegular, kNSToolbarIconSizeRegular);
    case QMacToolButton::IconSizeSmall:
        return QSize(kNSToolbarIconSizeSmall, kNSToolbarIconSizeSmall);
    case QMacToolButton::IconSizeDefault:
    default:
        return QSize(kNSToolbarIconSizeDefault, kNSToolbarIconSizeDefault);
    }
}

QMacToolButton::IconSize QMacNativeToolBar::iconSizeType() const
{
    switch ([d->toolbar sizeMode])
    {
    case NSToolbarSizeModeRegular:
        return QMacToolButton::IconSizeRegular;
    case NSToolbarSizeModeSmall:
        return QMacToolButton::IconSizeSmall;
    case NSToolbarSizeModeDefault:
    default:
        return QMacToolButton::IconSizeDefault;
    }
}

void QMacNativeToolBar::setIconSize(const QSize &iconSize)
{
    if (iconSize.isEmpty())
        setIconSize(QMacToolButton::IconSizeDefault);
    else if (iconSize.width() <= kNSToolbarIconSizeSmall && iconSize.height() <= kNSToolbarIconSizeSmall)
        setIconSize(QMacToolButton::IconSizeSmall);
    else
        setIconSize(QMacToolButton::IconSizeRegular);
}

void QMacNativeToolBar::setIconSize(QMacToolButton::IconSize iconSize)
{
    switch (iconSize)
    {
    case QMacToolButton::IconSizeRegular:
        [d->toolbar setSizeMode:NSToolbarSizeModeRegular];
        break;
    case QMacToolButton::IconSizeSmall:
        [d->toolbar setSizeMode:NSToolbarSizeModeSmall];
        break;
    case QMacToolButton::IconSizeDefault:
    default:
        [d->toolbar setSizeMode:NSToolbarSizeModeDefault];
        break;
    }
}

void QMacNativeToolBar::showCustomizationSheet()
{
    [d->toolbar runCustomizationPalette:nil];
}

QList<QMacToolButton *> QMacNativeToolBar::buttons()
{
    return d->delegate->items;
}

QList<QMacToolButton *> QMacNativeToolBar::allowedButtons()
{
    return d->delegate->allowedItems;
}

void QMacNativeToolBar::showInWindow(QWindow *window)
{
    targetWindow = window;
    QTimer::singleShot(100, this, SLOT(showInWindow_impl())); // ### hackety hack
}

void QMacNativeToolBar::showInWindow_impl()
{
    if (!targetWindow) {
        QTimer::singleShot(100, this, SLOT(showInWindow_impl()));
        return;
    }

    NSWindow *macWindow = static_cast<NSWindow*>(
        QGuiApplication::platformNativeInterface()->nativeResourceForWindow("nswindow", targetWindow));

    if (!macWindow) {
        QTimer::singleShot(100, this, SLOT(showInWindow_impl()));
        return;
    }

    [macWindow setToolbar: d->toolbar];
    [macWindow setShowsToolbarButton:YES];
}
void QMacNativeToolBar::removeFromWindow(QWindow *window)
{
    if (!window)
        return;

    NSWindow *macWindow = static_cast<NSWindow*>(
        QGuiApplication::platformNativeInterface()->nativeResourceForWindow("nswindow", window));
    [macWindow setToolbar:nil];
}


void QMacNativeToolBar::setSelectedItem()
{
//    setSelectedItem(qobject_cast<QMacToolButton*>(sender()));
}

//### TODO- re-implement
#if 0
QMacToolButton *QMacNativeToolBar::setSelectedItem(QMacToolButton *action)
{
    // If this action is checkable, find the corresponding NSToolBarItem on the
    // real NSToolbar and set it to the selected item if it is checked
    if (action && action->isCheckable())
    {
        checkSelectableItemSanity();

        foreach (QMacToolButton *toolButton, allowedButtons())
        {
            if (toolButton->m_action && toolButton->m_action->isChecked())
            {
                [d->toolbar setSelectedItemIdentifier:QtMac::toNSString(QString::number(qulonglong(toolButton)))];
                break;
            }
            else
            {
                [d->toolbar setSelectedItemIdentifier:nil];
            }
        }
    }

    return action;
}

void QMacNativeToolBar::checkSelectableItemSanity()
{
    // Find a list of all selectable actions
    QList<QMacToolButton*> selectableActions;
    foreach (QMacToolButton *button, allowedButtons())
        if (button->m_action && button->m_action->isCheckable())
            selectableActions.append(button->m_action);

    // If there's more than one, we need to do some sanity checks
    if (selectableActions.size() > 1)
    {
        // The action group that all selectable actions must belong to
        QMacToolButtonGroup *group = NULL;

        foreach (QMacToolButton *action, selectableActions)
        {
            // The first action group we find is "the" action group that
            // all selectable actions on the toolbar must belong to
            if (!group)
                group = action->actionGroup();

            // An action not having a group is a failure
            // All actions not belonging to the same group is a failure
            // The group not being exclusive is a failure
            if (!group || (group != action->actionGroup()) || (group && !group->isExclusive()))
            {
                qWarning() << "All selectable actions in a QMacUnifiedToolBar should belong to the same exclusive QMacToolButtonGroup if there is more than one selectable action.";
                break;
            }
        }
    }
}
#endif

QMacToolButton *QMacNativeToolBar::addAction(const QString &text)
{
    return [d->delegate addActionWithText:&text];
}

QMacToolButton *QMacNativeToolBar::addAction(const QIcon &icon, const QString &text)
{
    return [d->delegate addActionWithText:&text icon:&icon];
}

void QMacNativeToolBar::addSeparator()
{
    addStandardItem(QMacToolButton::Space); // No Seprator on OS X.
}

QMacToolButton *QMacNativeToolBar::addStandardItem(QMacToolButton::StandardItem standardItem)
{
    return [d->delegate addStandardItem:standardItem];
}

QMacToolButton *QMacNativeToolBar::addAllowedAction(const QString &text)
{
    return [d->delegate addAllowedActionWithText:&text];
}

QMacToolButton *QMacNativeToolBar::addAllowedAction(const QIcon &icon, const QString &text)
{
    return [d->delegate addAllowedActionWithText:&text icon:&icon];
}


QMacToolButton *QMacNativeToolBar::addAllowedStandardItem(QMacToolButton::StandardItem standardItem)
{
    return [d->delegate addAllowedStandardItem:standardItem];
}

QT_END_NAMESPACE

QT_USE_NAMESPACE

@implementation QNSToolbarNotifier

- (void)notification:(NSNotification*)note
{
    Q_ASSERT(pimpl);
    if ([[note name] isEqualToString:QtNSToolbarVisibilityChangedNotification])
        pimpl->fireVisibilityChanged();
    else if ([[note name] isEqualToString:QtNSToolbarShowsBaselineSeparatorChangedNotification])
        pimpl->fireShowsBaselineSeparatorChanged();
    else if ([[note name] isEqualToString:QtNSToolbarDisplayModeChangedNotification])
        pimpl->fireToolButtonStyleChanged();
    else if ([[note name] isEqualToString:QtNSToolbarSizeModeChangedNotification])
        pimpl->fireSizeModeChangedNotification();
    else if ([[note name] isEqualToString:QtNSToolbarAllowsUserCustomizationChangedNotification])
        pimpl->fireAllowsUserCustomizationChanged();
}

@end
