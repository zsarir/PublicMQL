//+------------------------------------------------------------------+
//|                                                      Message.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Vasiliy Sokolov."
#property link "http://www.mql5.com"
#include <Arrays/ArrayObj.mqh>
#include <Object.mqh>

#define UNKNOW_SOURCE "unknown" // An unknown source of messages

/**================================================================================================
 * *                                       Description
 * * This class implements a message object used by the logging system to track and store messages.
 * * Each message contains:
 * * - Type (info, warning, error)
 * * - Source (file/location where message originated)
 * * - Message text
 * * - System error ID and return codes
 * * - Timestamps (server and local time)
 * *
 * * The class provides methods to:
 * * - Create messages with different types and content
 * * - Get/set message properties
 * * - Format messages for console output and CSV storage
 * * - Track system errors and trade server return codes
 * *
 * * Used throughout the platform for:
 * * - Error reporting and logging
 * * - Trade operation status tracking
 * * - System notifications and warnings
 * * - Debug messages during development
 *================================================================================================**/

//+------------------------------------------------------------------+
//| Message type                                                     |
//+------------------------------------------------------------------+
enum ENUM_MESSAGE_TYPE
{
   MESSAGE_INFO,                  // Informational message
   MESSAGE_WARNING,               // Warning message
   MESSAGE_ERROR,                 // Error message
   MESSAGE_WRONG_POSITION_PARAMS, // uses when sl or tp is not set or the open price is not correct due to sl or tp
   MESSAGE_FAILD_POSITION,         // position failed to open or modify
   MESSAGE_FAILD_RESTORE_DATABASE, // failed to restore database
   MESSAGE_ORDER_INFO           // order info
};

//+------------------------------------------------------------------+
//| Message passed to the logging class                              |
//+------------------------------------------------------------------+
class CMessage : public CObject
{
 private:
   ENUM_MESSAGE_TYPE m_type; // Message type
   string m_source;          // Message source
   string m_text;            // Message text
   int m_system_error_id;    // Creates an ID of a SYSTEM error.
   int m_retcode;            // Contains a trade server return code
   datetime m_server_time;   // Trade server time at the moment of message creation
   datetime m_local_time;    // Local time at the moment of message creation
   void Init(ENUM_MESSAGE_TYPE type, string source, string text);
   bool m_active_debug_break_on_error;
   bool m_active_debug_break_on_failed_position;
   bool m_active_debug_break_on_wrong_position_params;
   bool m_active_debug_break_on_faild_restore_database;

 public:
   CMessage(void);
   CMessage(ENUM_MESSAGE_TYPE type);
   CMessage(ENUM_MESSAGE_TYPE type, string source, string text);
   void Type(ENUM_MESSAGE_TYPE type);
   ENUM_MESSAGE_TYPE Type(void);
   void Source(string source);
   string Source(void);
   void Text(string text);
   string Text(void);
   datetime TimeServer(void);
   datetime TimeLocal();
   void SystemErrorID(int error);
   int SystemErrorID();
   void Retcode(int retcode);
   int Retcode(void);
   string ToConsoleType(void);
   string ToCSVType(void);

   void debug_break_on_error(ENUM_MESSAGE_TYPE i_type)
   {
      if (i_type == MESSAGE_ERROR && m_active_debug_break_on_error)
      {
         DebugBreak();
      }
   }

   void debug_break_on_failed_position(ENUM_MESSAGE_TYPE i_type)
   {
      if (i_type == MESSAGE_FAILD_POSITION && m_active_debug_break_on_failed_position)
      {
         DebugBreak();
      }
   }

   void debug_break_on_wrong_position_params(ENUM_MESSAGE_TYPE i_type)
   {
      if (i_type == MESSAGE_WRONG_POSITION_PARAMS && m_active_debug_break_on_wrong_position_params)
      {
         DebugBreak();
      }
   }
   void debug_break_on_faild_restore_database(ENUM_MESSAGE_TYPE i_type)
   {
      if (i_type == MESSAGE_FAILD_RESTORE_DATABASE && m_active_debug_break_on_faild_restore_database)
      {
         DebugBreak();
      }
   }
   void init_debug_breaks()
   {
      m_active_debug_break_on_error = true;
      m_active_debug_break_on_failed_position = false;
      m_active_debug_break_on_wrong_position_params = false;
      m_active_debug_break_on_faild_restore_database = true;
   }
};

//+------------------------------------------------------------------+
//| By default no need to fill the time, it is created               |
//| automatically at the moment of object createion.                 |
//+------------------------------------------------------------------+
CMessage::CMessage(void)
{
   Init(MESSAGE_INFO, UNKNOW_SOURCE, "");
}

//+------------------------------------------------------------------+
//| Creates a message of a predefined type, message source and       |
//| text.                                                            |
//+------------------------------------------------------------------+
CMessage::CMessage(ENUM_MESSAGE_TYPE type, string source, string text)
{
   Init(type, source, text);
}

//+------------------------------------------------------------------+
//| Creates a message of a predefined type.                          |
//+------------------------------------------------------------------+
CMessage::CMessage(ENUM_MESSAGE_TYPE type)
{
   Init(type, UNKNOW_SOURCE, "");
}

//+------------------------------------------------------------------+
//| Serves as a basic constructor.                                   |
//+------------------------------------------------------------------+
void CMessage::Init(ENUM_MESSAGE_TYPE type, string source, string text)
{
   init_debug_breaks();

   debug_break_on_error(type);
   debug_break_on_failed_position(type);
   debug_break_on_wrong_position_params(type);
   debug_break_on_faild_restore_database(type);

   m_server_time = TimeCurrent();
   m_local_time = TimeLocal();
   m_type = type;
   m_source = source;
   m_text = text;
   m_system_error_id = GetLastError();
}

//+------------------------------------------------------------------+
//| Returns the message type.                                        |
//+------------------------------------------------------------------+
ENUM_MESSAGE_TYPE CMessage::Type(void)
{
   return m_type;
}

//+------------------------------------------------------------------+
//| Sets the message source.                                         |
//+------------------------------------------------------------------+
void CMessage::Source(string source)
{
   m_source = source;
}

//+------------------------------------------------------------------+
//| Returns the message source.                                      |
//+------------------------------------------------------------------+
string CMessage::Source(void)
{
   return m_source;
}

//+------------------------------------------------------------------+
//| Sets message contents.                                           |
//+------------------------------------------------------------------+
void CMessage::Text(string text)
{
   m_text = text;
}

//+------------------------------------------------------------------+
//| Returns the message contents.                                    |
//+------------------------------------------------------------------+
string CMessage::Text(void)
{
   return m_text;
}

//+------------------------------------------------------------------+
//| Returns server time at the moment of message creation            |
//+------------------------------------------------------------------+
datetime CMessage::TimeServer(void)
{
   return m_server_time;
}

//+------------------------------------------------------------------+
//| Returns local time at the moment of message creation.            |
//+------------------------------------------------------------------+
datetime CMessage::TimeLocal(void)
{
   return m_local_time;
}

//+------------------------------------------------------------------+
//| Returns message string to display in the terminal window         |
//+------------------------------------------------------------------+
string CMessage::ToConsoleType(void)
{
   string dt = ";";
   string t = EnumToString(m_type);
   t = StringSubstr(t, 8);
   string text = t + dt + m_source + dt + m_text + dt +
                 TimeToString(m_server_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS);
   return text;
}

//+------------------------------------------------------------------+
//| Returns message string to add to the log file.                   |
//+------------------------------------------------------------------+
string CMessage::ToCSVType(void)
{
   string d = "\t"; // Separator of message columns
   string msg = TimeToString(m_server_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS) + d + EnumToString(m_type) + d + m_source + d + m_text;
   return msg;
}

//+------------------------------------------------------------------+
//| Returns code of the saved error.                                 |
//+------------------------------------------------------------------+
int CMessage::SystemErrorID(void)
{
   return m_system_error_id;
}

//+------------------------------------------------------------------+
//| Sets the error code corresponding to the message. This           |
//| can be a system or user error code.                              |
//| NOTE: The last error is set automatically while a message        |
//| is being created. That is why you should call this method        |
//| only in special cases.                                           |
//+------------------------------------------------------------------+
void CMessage::SystemErrorID(int error)
{
   m_system_error_id = error;
}

//+------------------------------------------------------------------+
//| Sets the trade server response code. Unlike                      |
//| SystemErrorID, requires explicit setting, since CMessage has     |
//| no access to trade server response.                              |
//+------------------------------------------------------------------+
void CMessage::Retcode(int retcode)
{
   m_retcode = retcode;
}

//+------------------------------------------------------------------+
//| Returns the user defined response code received from a trade     |
//| server.  This field needs to be analyzed only in cases where     |
//| the received message is connected with trading actions.          |
//+------------------------------------------------------------------+
int CMessage::Retcode(void)
{
   return m_retcode;
}
//+------------------------------------------------------------------+
