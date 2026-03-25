from typing import List, Dict, Any, Optional
from pydantic import BaseModel
import uuid

from pydantic import BaseModel, Field

class A2UIWidget(BaseModel):
    type: str # 'text', 'button', 'text_input', 'datepicker', 'timepicker', 'select', 'confirmation_card', 'column', 'meeting_form'
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    data: Dict[str, Any]

    def __init__(self, **data):
        super().__init__(**data)
        # print(f"DEBUG: [WIDGET] Created {self.type} widget with ID {self.id}", flush=True)

    def with_custom_labels(self, confirm: str, cancel: str) -> 'A2UIWidget':
        if self.type == "confirmation_card":
            self.data["confirm_label"] = confirm
            self.data["cancel_label"] = cancel
        return self

    def with_edit_button(self, label: str, action: str) -> 'A2UIWidget':
        if self.type == "confirmation_card":
            self.data["edit_label"] = label
            self.data["edit_action"] = action
        return self

class A2UIResponse(BaseModel):
    session_id: str
    message: str
    ui: List[A2UIWidget]
    state: Optional[Dict[str, Any]] = None

class UIGenerator:
    @staticmethod
    def column(children: List[A2UIWidget]) -> A2UIWidget:
        return A2UIWidget(type="column", data={"children": [c.dict() for c in children]})

    @staticmethod
    def text(content: str) -> A2UIWidget:
        return A2UIWidget(type="text", data={"content": content})

    @staticmethod
    def button(label: str, action: str, variant: str = "primary", icon: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="button", data={
            "label": label,
            "action": action,
            "variant": variant,
            "icon": icon
        })

    @staticmethod
    def text_input(label: str, action: str, placeholder: str = "", multiline: bool = False) -> A2UIWidget:
        return A2UIWidget(type="text_input", data={
            "label": label,
            "action": action,
            "placeholder": placeholder,
            "multiline": multiline
        })

    @staticmethod
    def text_input_with_button(label: str, action: str, button_label: str, button_action: str) -> A2UIWidget:
        return A2UIWidget(type="text_input_with_button", data={
            "label": label,
            "action": action,
            "button_label": button_label,
            "button_action": button_action
        })

    @staticmethod
    def datepicker(label: str, action: str, initial_date: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="datepicker", data={
            "label": label,
            "action": action,
            "initial_date": initial_date
        })

    @staticmethod
    def timepicker(label: str, action: str, initial_time: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="timepicker", data={
            "label": label,
            "action": action,
            "initial_time": initial_time
        })

    @staticmethod
    def select(label: str, action: str, options: List[Dict[str, str]]) -> A2UIWidget:
        return A2UIWidget(type="select", data={
            "label": label,
            "action": action,
            "options": options
        })

    @staticmethod
    def multi_select(label: str, action: str, options: List[Dict[str, str]]) -> A2UIWidget:
        return A2UIWidget(type="multi_select", data={
            "label": label,
            "action": action,
            "options": options
        })

    @staticmethod
    def confirmation_card(title: str, fields: List[Dict[str, str]], confirm_action: str, cancel_action: str, edit_action: Optional[str] = None) -> A2UIWidget:
        data = {
            "title": title,
            "fields": fields,
            "confirm_label": "Confirm",
            "confirm_action": confirm_action,
            "cancel_label": "Cancel",
            "cancel_action": cancel_action
        }
        if edit_action:
            data["edit_label"] = "Edit"
            data["edit_action"] = edit_action
        return A2UIWidget(type="confirmation_card", data=data)

    @staticmethod
    def task_form(collected_fields: Dict[str, Any], next_field: str) -> List[A2UIWidget]:
        prompts = {
            "title": "What's the title of the task?",
            "from": "When should the task start?",
            "to": "When should it end?",
            "assignUserId": "Who should be assigned?"
        }
        
        ui = [UIGenerator.text(prompts.get(next_field, f"Please provide {next_field}"))]
        
        if next_field in ["from", "to"]:
            ui.append(UIGenerator.datepicker(f"{next_field.capitalize()} Date", f"set_{next_field}_date"))
            ui.append(UIGenerator.timepicker(f"{next_field.capitalize()} Time", f"set_{next_field}_time"))
            ui.append(UIGenerator.button("Next", f"action_submit_{next_field}"))
        elif next_field == "assignUserId":
            ui.append(UIGenerator.text_input_with_button(
                "Assignee ID or Name", 
                "set_assignee", 
                "Submit Assignee", 
                "action_submit_assignUserId"
            ))
        else:
            ui.append(UIGenerator.text_input_with_button(
                next_field.capitalize(), 
                f"set_{next_field}", 
                f"Submit {next_field.capitalize()}", 
                f"action_submit_{next_field}"
            ))
            
        return ui

    @staticmethod
    def meeting_form(next_field: str) -> List[A2UIWidget]:
        prompts = {
            "title": "What's the meeting title?",
            "meetingDate": "Select the meeting date",
            "from": "Start time?",
            "to": "End time?",
            "attendessRef": "Who are the attendees?",
            "isTeam": "Is this a Teams meeting?"
        }
        
        ui = [UIGenerator.text(prompts.get(next_field, f"Please provide {next_field}"))]
        
        if next_field == "meetingDate":
            ui.append(UIGenerator.datepicker("Meeting Date", "set_meetingDate"))
        elif next_field in ["from", "to"]:
            ui.append(UIGenerator.timepicker(next_field.capitalize(), f"set_{next_field}"))
        elif next_field == "isTeam":
            ui.append(UIGenerator.select("Teams Meeting?", "set_isTeam", [
                {"label": "Yes", "value": "true"},
                {"label": "No", "value": "false"}
            ]))
        else:
            ui.append(UIGenerator.text_input_with_button(
                next_field.capitalize(), 
                f"set_{next_field}", 
                f"Submit {next_field.capitalize()}", 
                f"action_submit_{next_field}"
            ))
            
        return ui

    @staticmethod
    def comprehensive_meeting_form(user_options: List[Dict[str, str]], initial_values: Optional[Dict[str, Any]] = None) -> A2UIWidget:
        return A2UIWidget(type="meeting_form", data={
            "user_options": user_options,
            "initial_values": initial_values,
            "submit_action": "action_submit_full_meeting_form"
        })

    @staticmethod
    def comprehensive_task_form(user_options: List[Dict[str, str]], initial_values: Optional[Dict[str, Any]] = None) -> A2UIWidget:
        return A2UIWidget(type="task_form", data={
            "user_options": user_options,
            "initial_values": initial_values,
            "submit_action": "action_submit_full_task_form"
        })

    @staticmethod
    def comprehensive_leave_form(leave_quota: List[Dict[str, Any]]) -> A2UIWidget:
        return A2UIWidget(type="leave_form", data={
            "leave_quota": leave_quota,
            "submit_action": "action_submit_full_leave_form"
        })

    @staticmethod
    def user_selection(title: str, users: List[Dict[str, Any]], on_select_action: str) -> A2UIWidget:
        return A2UIWidget(type="user_selection", data={
            "title": title,
            "users": users,
            "onSelectAction": on_select_action
        })
    @staticmethod
    def meeting_grid(meetings: List[Dict[str, Any]]) -> A2UIWidget:
        return A2UIWidget(type="meeting_grid", data={
            "meetings": meetings
        })

    @staticmethod
    def task_grid(tasks: List[Dict[str, Any]]) -> A2UIWidget:
        return A2UIWidget(type="task_grid", data={
            "tasks": tasks
        })

    @staticmethod
    def meeting_calendar(meetings: List[Dict[str, Any]], initial_date: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="meeting_calendar", data={
            "meetings": meetings,
            "initial_date": initial_date
        })

    @staticmethod
    def task_calendar(tasks: List[Dict[str, Any]], initial_date: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="task_calendar", data={
            "tasks": tasks,
            "initial_date": initial_date
        })

    @staticmethod
    def unified_calendar(items: List[Dict[str, Any]], initial_date: Optional[str] = None) -> A2UIWidget:
        return A2UIWidget(type="unified_calendar", data={
            "items": items,
            "initial_date": initial_date
        })

    @staticmethod
    def bar_chart(title: str, labels: List[str], values: List[float], x_label: str = "", y_label: str = "") -> A2UIWidget:
        return A2UIWidget(type="bar_chart", data={
            "title": title,
            "labels": labels,
            "values": values,
            "x_label": x_label,
            "y_label": y_label
        })

    @staticmethod
    def pie_chart(title: str, data: List[Dict[str, Any]]) -> A2UIWidget:
        """
        data: List of {"label": str, "value": float, "color": Optional[str]}
        """
        return A2UIWidget(type="pie_chart", data={
            "title": title,
            "data": data
        })
    @staticmethod
    def selection_card(title: str, options: List[Dict[str, str]]) -> A2UIWidget:
        """
        options: List of {"label": str, "value": str}
        """
        return A2UIWidget(type="selection_card", data={
            "title": title,
            "options": options
        })
