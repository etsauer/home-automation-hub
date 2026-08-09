---
name: pickup
description: Pick up a handoff document and continue the work from where the previous agent left off.
argument-hint: What is the handoff document you want to pick up?
---

A previous agent has created a handoff document summarizing the current conversation. Your task is to pick up that document and continue the work from where the previous agent left off.

The document will be saved to a temporary directory of the user's OS, not the current workspace. You should read the handoff document, understand the context, and continue the work accordingly.

Once the handoff document is read, you should provide a summary of the current state of the work, any pending tasks, and any relevant information that will help you continue the work effectively. Then prompt the user for permission to delete the document.
