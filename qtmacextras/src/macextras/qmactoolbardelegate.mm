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

#include "qmactoolbardelegate_p.h"

#include <QtGui/QImage>
#include <QtGui/QPixmap>

#include "qmacfunctions.h"
#include "qmacfunctions_p.h"
#include "qmacnativetoolbar_p.h"

QT_USE_NAMESPACE

NSArray *toNSArray(const QList<QString> &stringList)
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    foreach (const QString &string, stringList) {
        [array addObject : QtMac::toNSString(string)];
    }
    return array;
}

NSString *toNSStandardItem(QMacToolButton::StandardItem standardItem);

NSMutableArray *itemIdentifiers(const QList<QMacToolButton *> &items, bool cullUnselectable)
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    foreach (const QMacToolButton * item, items) {
        if (cullUnselectable && item->selectable() == false)
            continue;
        if (item->standardItem() == QMacToolButton::NoItem) {
            [array addObject : QtMac::toNSString(QString::number(qulonglong(item)))];
        } else {
            [array addObject : toNSStandardItem(item->standardItem())];
        }
    }
    return array;
}

// from QMacToolButton.cpp
QString qt_strippedText(QString s)
{
    s.remove( QString::fromLatin1("...") );
    int i = 0;
    while (i < s.size()) {
        ++i;
        if (s.at(i-1) != QLatin1Char('&'))
            continue;
        if (i < s.size() && s.at(i) == QLatin1Char('&'))
            ++i;
        s.remove(i-1,1);
    }
    return s.trimmed();
}

@implementation QMacToolbarDelegate

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    Q_UNUSED(toolbar);
    return itemIdentifiers(self->items, false);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    Q_UNUSED(toolbar);
    return itemIdentifiers(self->allowedItems, false);
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar
{
    Q_UNUSED(toolbar);
    NSMutableArray *array = itemIdentifiers(self->items, true);
    [array addObjectsFromArray :  itemIdentifiers(self->allowedItems, true)];
    return array;
}

- (IBAction)itemClicked:(id)sender
{
    NSToolbarItem *item = reinterpret_cast<NSToolbarItem *>(sender);
    QString identifier = QtMac::fromNSString([item itemIdentifier]);
    QMacToolButton *toolButton = reinterpret_cast<QMacToolButton *>(identifier.toULongLong());
    toolButton->emitActivated();
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdentifier willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    Q_UNUSED(toolbar);
    Q_UNUSED(willBeInserted);
    const QString identifier = QtMac::fromNSString(itemIdentifier);

    QMacToolButton *toolButton = reinterpret_cast<QMacToolButton *>(identifier.toULongLong()); // string -> unisgned long long -> pointer
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
    [toolbarItem setLabel: QtMac::toNSString(toolButton->text())];
    [toolbarItem setPaletteLabel :[toolbarItem label]];

    QPixmap icon = toolButton->icon().pixmap(64, 64);
    if (icon.isNull() == false) {
        [toolbarItem setImage: QtMac::toNSImage(icon)];
    }

    [toolbarItem setTarget : self];
    [toolbarItem setAction : @selector(itemClicked:)];

    return toolbarItem;
}

- (QMacToolButton *)addActionWithText:(const QString *)text
{
    QIcon nullIcon;
    return [self addActionWithText:text icon:&nullIcon];
}

- (QMacToolButton *)addActionWithText:(const QString *)text icon:(const QIcon *)icon
{
    QMacToolButton *button = new QMacToolButton(0);
    button->setText(*text);
    button->setIcon(*icon);
    items.append(button);
    allowedItems.append(button);
    return button;
}

- (QMacToolButton *)addStandardItem:(QMacToolButton::StandardItem) standardItem
{
    QMacToolButton *button = new QMacToolButton(0);
    button->setStandardItem(standardItem);
    items.append(button);
    allowedItems.append(button);
    return button;
}

- (QMacToolButton *)addAllowedActionWithText:(const QString *)text
{
    QIcon nullIcon;
    return [self addAllowedActionWithText:text icon:&nullIcon];
}

- (QMacToolButton *)addAllowedActionWithText:(const QString *)text icon:(const QIcon *)icon
{
    QMacToolButton *button = new QMacToolButton(0);
    button->setText(*text);
    button->setIcon(*icon);
    allowedItems.append(button);
    return button;
}

- (QMacToolButton *)addAllowedStandardItem:(QMacToolButton::StandardItem)standardItem
{
    QMacToolButton *button = new QMacToolButton(0);
    button->setStandardItem(standardItem);
    allowedItems.append(button);
    return button;
}


@end
