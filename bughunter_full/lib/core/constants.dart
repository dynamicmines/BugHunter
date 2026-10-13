const String nazvanieProekta = 'BugHunter';
const String podzagolovok = 'Тренажёр поиска ошибок в коде';

/// Адрес файла с новыми уровнями и задачами (content.json).
/// Пусто: контент берётся только из приложения.
/// Чтобы заработало обновление без переустановки, выложите content.json
/// по прямой ссылке (например, GitHub Raw) и вставьте её сюда.
const String kContentUrl = '';

/// Пока нет сервера, письма не уходят. В демо-режиме код из «письма»
/// показывается прямо на экране ввода кода. Когда появится бэкенд, поставьте false.
const bool kDemoMail = true;

const int kCodeLength = 6;
const int kCodeMinutes = 10;
const int kResendSeconds = 30;
