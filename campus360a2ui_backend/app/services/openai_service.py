import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
from langchain_openai import AzureChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field

load_dotenv()

class IntentResponse(BaseModel):
    intent: str = Field(description="The detected intent: 'attendance', 'task', 'meeting', 'create_meeting', 'leave', 'general_question', or 'unknown'")
    entities: dict = Field(default_factory=dict, description="Extracted entities like dates, titles, etc.")
    response_text: str = Field(description="A natural language response to the user")

class OpenAIService:
    def __init__(self):
        self.llm = AzureChatOpenAI(
            azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o"),
            openai_api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-08-01-preview"),
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            temperature=0
        )
        self.parser = JsonOutputParser(pydantic_object=IntentResponse)

    async def detect_intent(self, user_message: str, current_context: str = "") -> IntentResponse:
        # Calculate current date (UTC+5:30)
        now = datetime.utcnow() + timedelta(hours=5, minutes=30)
        today_date = now.strftime("%A, %d %B %Y")
        
        system_prompt = f"""You are Mandoobee AI, the professional and friendly personal assistant for the Mandoobee app. 
Current Date: {today_date}

Your primary purpose is to serve as a conversational interface that enables users to perform actions within the Mandoobee app through simple chat, instead of manually navigating through menus and forms. 
You act as a bridge between the user and the app's features (Attendance, Tasks, Meetings, Leaves).

Supported Intents:
1. 'attendance': managing your daily presence (check-in, check-out, punch-in).
2. 'task': managing your work items (create, view, list tasks).
3. 'meeting': managing your schedule (view, list meetings).
4. 'create_meeting': SPECIFICALLY for scheduling a NEW meeting. Mandatory for any request that involves BOOKING or SCHEDULING a meeting.
5. 'leave': managing your time off (apply for leave, check balance, view history).
6. 'general_question': Questions about Meerana company, services, team, leadership, or company information.
7. 'unknown': General conversation, greetings, compliments, or questions about who you are.

For 'unknown' intent:
- Still provide a natural, polite, and conversational 'response_text' that acknowledges what the user said.
- If the user says something nice like 'nice', 'cool', 'thanks', respond warmly.
- When asked 'who are you?' or about your purpose, explain that you are Mandoobee AI, designed to make using the Mandoobee app faster and more intuitive by handling requests through simple conversation.
- Always keep the tone professional yet helpful.

Entities to extract:
- 'date': ALWAYS resolve relative dates like 'tomorrow', 'next week', 'Friday', 'next Monday' to a specific date string in 'YYYY-MM-DD' format based on Current Date: {today_date}. If a range is mentioned, provide it as 'YYYY-MM-DD to YYYY-MM-DD'. Example: If today is Friday, 'next Monday' is the following Monday.
- 'time': mentioned times.
- 'title': subject of task/meeting.
- 'description': detailed description or content of the task/meeting.
- 'person': assignee/attendee.

Extraction Rules for 'create_meeting':
- 'provider': if user says "Outlook" -> "outlook", if "Teams" -> "teams", if nothing -> null.
- 'attendee_name': Name of person being invited.
- 'datetime': ISO8601 start time.
- 'duration_minutes': integer (default 30).

Output format:
{{format_instructions}}

Current conversation context:
{{context}}"""

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            ("user", "{message}")
        ])
        
        chain = prompt | self.llm | self.parser
        
        result = await chain.ainvoke({
            "message": user_message,
            "context": current_context,
            "format_instructions": self.parser.get_format_instructions()
        })
        
        return IntentResponse(**result)
