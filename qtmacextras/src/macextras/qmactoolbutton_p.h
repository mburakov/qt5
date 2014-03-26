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

#ifndef QMACTOOLBUTTON_H
#define QMACTOOLBUTTON_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtGui/QIcon>

QT_BEGIN_NAMESPACE

class QMacToolButton : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool selectable READ selectable WRITE setSelectable)
    Q_PROPERTY(StandardItem standardItem READ standardItem WRITE setStandardItem)
    Q_PROPERTY(QString text READ text WRITE setText)
    Q_PROPERTY(QIcon icon READ icon WRITE setIcon)
    Q_ENUMS(StandardItem)
public:
    enum StandardItem
    {
        NoItem,
        ShowColors,
        ShowFonts,
        PrintItem,
        Space,
        FlexibleSpace
    };

    enum IconSize
    {
        IconSizeDefault,
        IconSizeRegular,
        IconSizeSmall
    };

    QMacToolButton();
    QMacToolButton(QObject *parent);
    virtual ~QMacToolButton();

    bool selectable() const;
    void setSelectable(bool selectable);

    StandardItem standardItem() const;
    void setStandardItem(StandardItem standardItem);

    QString text() const;
    void setText(const QString &text);

    QIcon icon() const;
    void setIcon(const QIcon &icon);
Q_SIGNALS:
    void activated();
private:
    bool m_selectable;
    StandardItem m_standardItem;
    QString m_text;
    QIcon m_icon;

public: // (not really public)
    void emitActivated() { Q_EMIT activated(); }
};

QT_END_NAMESPACE

#endif
