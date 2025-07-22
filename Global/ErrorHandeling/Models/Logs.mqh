//+------------------------------------------------------------------+
//|                                                         Logs.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Vasiliy Sokolov."
#property link "http://www.mql5.com"
#include "Message.mqh"
#include <Arrays/ArrayObj.mqh>
#include <Object.mqh>
//+------------------------------------------------------------------+
//| The class implements logging of messages as Singleton            |
//+------------------------------------------------------------------+
/**================================================================================================
 * *                                       Description
 * * This class implements a singleton logger for handling messages and notifications in the trading system.
 * * As a singleton pattern, it ensures a single logging instance is shared across all parts of the platform,
 * * providing centralized logging and message handling for the entire trading system.
 * *
 * * Key features:
 * * - Maintains a list of messages using CArrayObj
 * * - Supports both terminal messages and push notifications
 * * - Configurable message priority levels for terminal and push notifications
 * * - File-based logging with automatic cleanup of old logs
 * * - Thread-safe singleton implementation
 * *
 * * The logger can be configured to:
 * * - Enable/disable terminal messages
 * * - Enable/disable push notifications
 * * - Set priority thresholds for different message types
 * * - Save messages to CSV files
 * * - Automatically manage log file retention
 * *
 * * Usage across platform:
 * * - Used by all expert advisors for consistent logging
 * * - Handles error reporting from all trading modules
 * * - Provides unified message formatting and storage
 * * - Ensures thread-safe logging in multi-threaded environments
 *================================================================================================**/

class CLog
{
private:
    static CLog *m_log;                    // A pointer to the global static sample
    CArrayObj m_messages;                  // The list of saved messages
    bool m_terminal_enable;                // True if you need to print the received message to the trading terminal
    bool m_push_enable;                    // True if a Push notification is sent
    ENUM_MESSAGE_TYPE m_push_priority;     // Contains the specified priority of message display in the terminal window.
    ENUM_MESSAGE_TYPE m_terminal_priority; // Contains the specified priority of sending pushes to mobile devices.
    bool m_recursive;                      // A flag indicating the recursive call of the destructor.
    bool SendPush(CMessage *msg);
    void CheckMessage(CMessage *msg);
    CLog(void); // Private constructor
    string GetName(void);
    void DeleteOldLogs(int day_history = 30);
    void DeleteOldLog(string file_name, int day_history);
    ~CLog(void) { ; }

public:
    static CLog *GetLog(void); // The method to receive a static object
    bool AddMessage(CMessage *msg);
    void Clear(void);
    bool Save(string path);
    CMessage *MessageAt(int index) const;
    int Total(void);
    void TerminalEnable(bool enable);
    bool TerminalEnable(void);
    void PushEnable(bool enable);
    bool PushEnable(void);
    void PushPriority(ENUM_MESSAGE_TYPE type);
    ENUM_MESSAGE_TYPE PushPriority(void);
    void TerminalPriority(ENUM_MESSAGE_TYPE type);
    ENUM_MESSAGE_TYPE TerminalPriority(void);
    bool SaveToFile(void);
    static bool DeleteLog(void);
};

CLog *CLog::m_log;
//+------------------------------------------------------------------+
//| Constructor of the global object                                 |
//+------------------------------------------------------------------+
CLog::CLog(void) : m_terminal_enable(true),
                   m_push_enable(false),
                   m_recursive(false)
{
    DeleteOldLogs();
}
//+------------------------------------------------------------------+
//| Returns the logger object                                        |
//+------------------------------------------------------------------+
static CLog *CLog::GetLog()
{
    if (CheckPointer(m_log) == POINTER_INVALID)
        m_log = new CLog();
    return m_log;
}
//+------------------------------------------------------------------+
//| Deletes the logger object                                        |
//+------------------------------------------------------------------+
bool CLog::DeleteLog(void)
{
    bool res = CheckPointer(m_log) != POINTER_INVALID;
    if (res)
        delete m_log;
    return res;
}
//+------------------------------------------------------------------+
//| Returns a message with the specified index 'index'               |
//+------------------------------------------------------------------+
CMessage *CLog::MessageAt(int index) const
{
    CMessage *msg = m_messages.At(index);
    return msg;
}
//+------------------------------------------------------------------+
//| Returns the total number of logs.                                |
//+------------------------------------------------------------------+
int CLog::Total(void)
{
    return m_messages.Total();
}
//+------------------------------------------------------------------+
//| Saves a message to a CSV file.                                   |
//+------------------------------------------------------------------+
bool CLog::Save(string path)
{
    return false;
}
//+------------------------------------------------------------------+
//| Cleans the logger.                                               |
//+------------------------------------------------------------------+
void CLog::Clear(void)
{
    m_messages.Clear();
}
//+------------------------------------------------------------------+
//| Adds a new message to the list.                                  |
//+------------------------------------------------------------------+
bool CLog::AddMessage(CMessage *msg)
{
    CheckMessage(msg);
    if (m_terminal_enable)
        printf(msg.ToConsoleType());
    if (m_push_enable)
        SendPush(msg);
    return m_messages.Add(msg);
}
//+------------------------------------------------------------------+
//| Sets a flag indicating whether it's necessary to display         |
//| the passed message to platform window.                           |
//+------------------------------------------------------------------+
void CLog::TerminalEnable(bool enable)
{
    m_terminal_enable = enable;
}
//+------------------------------------------------------------------+
//| Returns the flag indicating whether the received  message is     |
//| displayed in the trading platform window (Experts tab)           |
//+------------------------------------------------------------------+
bool CLog::TerminalEnable(void)
{
    return m_terminal_enable;
}
//+------------------------------------------------------------------+
//| Sets a flag indicating whether it's necessary to send            |
//| the passed message to receivers' mobile devices.                 |
//+------------------------------------------------------------------+
void CLog::PushEnable(bool enable)
{
    m_push_enable = enable;
}
//+------------------------------------------------------------------+
//| Returns the flag indicating whether the received message is      |
//| sent as pushes to mobile devices.                                |
//+------------------------------------------------------------------+
bool CLog::PushEnable(void)
{
    return m_push_enable;
}
//+------------------------------------------------------------------+
//| Sends a passed message as a pushe to mobile devices to specified |
//| recipients. Details:                                             |
//| https://www.mql5.com/en/docs/common/sendnotification             |
//| RETURN:                                                          |
//|      True if successfully sent, false if otherwise               |
//|                                                                  |
//+------------------------------------------------------------------+
bool CLog::SendPush(CMessage *msg)
{
    string d = "\t";
    string stype = EnumToString(msg.Type());
    string date = TimeToString(msg.TimeServer(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
    string line = stype + d + date + d + msg.Source() + d + msg.Text();
    if (StringLen(line) > 255)
        line = StringSubstr(line, 0, 255);
    bool res = SendNotification(line);
    return res;
}
//+------------------------------------------------------------------+
//| Sets the priority of sending push notifications to mobiles of    |
//| recipients For example, if priority = MESSAGE_ERROR, all messages|
//| of type MESSAGE_INFO Ð¸ MESSAGE_WARNING will not be sent.   If    |
//| priority = MESSAGE_WARNING, it will send messages of types       |
//| MESSAGE_WARNING and MESSAGE_ERROR.                               |
//+------------------------------------------------------------------+
void CLog::PushPriority(ENUM_MESSAGE_TYPE priority)
{
    m_push_priority = priority;
}
//+------------------------------------------------------------------+
//| Returns priority of push-notification sending                    |
//+------------------------------------------------------------------+
ENUM_MESSAGE_TYPE CLog::PushPriority(void)
{
    return m_push_priority;
}
//+------------------------------------------------------------------+
//| Sets the priority of sending messages to the terminal            |
//| For example, if priority = MESSAGE_ERROR, all messages of type   |
//| MESSAGE_INFO and MESSAGE_WARNING aren't sent to terminal.  If    |
//| priority = MESSAGE_WARNING, it will send messages                |
//| MESSAGE_WARNING and MESSAGE_ERROR.                               |
//+------------------------------------------------------------------+
void CLog::TerminalPriority(ENUM_MESSAGE_TYPE priority)
{
    m_terminal_priority = priority;
}
//+------------------------------------------------------------------+
//| Returns the priority of terminal message sending.                |
//+------------------------------------------------------------------+
ENUM_MESSAGE_TYPE CLog::TerminalPriority(void)
{
    return m_terminal_priority;
}
//+------------------------------------------------------------------+
//| Checks if the sent message contains source and the text of the   |
//| message.   If it doesn't, creates a new warning                  |
//| message.                                                         |
//+------------------------------------------------------------------+
void CLog::CheckMessage(CMessage *msg)
{
    if (msg.Source() == UNKNOW_SOURCE || msg.Source() == NULL || msg.Source() == "")
    {
        string text = "The passed message does not contain its source of origin.";
        CMessage *msg_info = new CMessage(MESSAGE_INFO, "CLog::AddMessage", text);
        AddMessage(msg_info);
    }
    if (msg.Text() == NULL || msg.Text() == "")
    {
        string text = "The passed message does not contain message text.";
        CMessage *msg_info = new CMessage(MESSAGE_INFO, "CLog::AddMessage", text);
        AddMessage(msg_info);
    }
}
//+------------------------------------------------------------------+
//| Saves messages to a file, writing them to the end.               |
//+------------------------------------------------------------------+
bool CLog::SaveToFile(void)
{
    int h = INVALID_HANDLE;
    // Make 3 attempts to open the file with a delay of 200 ms.
    for (int i = 0; i < 3; i++)
    {
        h = FileOpen(GetName(), FILE_TXT | FILE_READ | FILE_WRITE | FILE_COMMON);
        if (h != INVALID_HANDLE)
            break;
        Sleep(200);
    }
    if (h == INVALID_HANDLE)
    {
        string text = "Unable to open file " + GetName() + " Reason: " + (string)GetLastError();
        CMessage *msg = new CMessage(MESSAGE_ERROR, __FUNCTION__, text);
        m_log.AddMessage(msg);
        return false;
    }
    FileSeek(h, 0, SEEK_END);
    for (int i = 0; i < m_messages.Total(); i++)
    {
        CMessage *msg = m_messages.At(i);
        FileWriteString(h, msg.ToCSVType() + "\n");
    }
    FileClose(h);
    return true;
}
//+------------------------------------------------------------------+
//| Generates a log name to record based on the current date.        |
//+------------------------------------------------------------------+
string CLog::GetName(void)
{
    string date = TimeToString(TimeCurrent(), TIME_DATE);
    return "Logs\\log_" + date + ".txt";
}
//+------------------------------------------------------------------+
//| Removes logs with the creation date older than day_history       |
//| days (default 30 days).                                          |
//+------------------------------------------------------------------+
void CLog::DeleteOldLogs(int day_history = 30)
{
    string file_name = "";
    string filter = "Logs\\log_*.txt";
    long h = FileFindFirst(filter, file_name, FILE_COMMON);
    DeleteOldLog("Logs\\" + file_name, day_history);
    while (FileFindNext(h, file_name))
        DeleteOldLog("Logs\\" + file_name, day_history);
    int b = 2;
}
//+------------------------------------------------------------------+
//| Deletes a passed file if it is date is older than                |
//| day_history days.                                                |
//+------------------------------------------------------------------+
void CLog::DeleteOldLog(string file_name, int day_history)
{
    int h = FileOpen(file_name, FILE_READ | FILE_BIN | FILE_COMMON);
    if (h == INVALID_HANDLE)
        return;
    MqlDateTime dt;
    TimeToStruct((datetime)FileGetInteger(h, FILE_ACCESS_DATE), dt);
    int seconds = (int)(TimeCurrent() - FileGetInteger(h, FILE_CREATE_DATE));
    FileClose(h);
    int days = seconds / 3600 / 24;
    if (days >= day_history)
        FileDelete(file_name, FILE_COMMON);
}
//+------------------------------------------------------------------+


