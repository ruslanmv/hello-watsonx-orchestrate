"""
A minimal Python tool that the Calculator Agent can call.

The @tool decorator registers the function with the ADK so it
appears in the local Orchestrate Developer-Edition catalogue.
"""

from typing import Annotated

from orchestrate_sdk import tool                # ADK helper
from pydantic import Field


@tool(
    name="add",
    description="Add two integers and return a formatted string.",
)
def add(
    a: Annotated[int, Field(description="The first integer")],
    b: Annotated[int, Field(description="The second integer")],
) -> str:
    """
    Adds two integers.

    Parameters
    ----------
    a : int
        first operand
    b : int
        second operand

    Returns
    -------
    str
        user-friendly sentence with the result
    """
    result = a + b
    return f"The result of {a} + {b} is {result}."
