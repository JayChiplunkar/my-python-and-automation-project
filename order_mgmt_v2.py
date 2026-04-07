# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
import motor.motor_asyncio

# MongoDB connection
client = motor.motor_asyncio.AsyncIOMotorClient("mongodb://localhost:27017")
db = client["order_db"]
orders_collection = db["orders"]

# FastAPI app
app = FastAPI(title="OrderBooking API", description="CRUD API with MongoDB", version="1.0.0")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model (no status field exposed to user)
class OrderBooking(BaseModel):
    customer_name: str
    product: str
    quantity: int
    price: float

class OrderUpdate(BaseModel):
    customer_name: Optional[str] = ""
    product: Optional[str] = ""
    quantity: Optional[int] = 0
    price: Optional[float] = 0.0
# class OrderUpdate(BaseModel):
#     customer_name: Optional[str] = None
#     product: Optional[str] = None
#     quantity: Optional[int] = None
#     price: Optional[float] = None

# Helper to convert Mongo ObjectId
def order_helper(order) -> dict:
    return {
        "id": str(order["_id"]),
        "customer_name": order["customer_name"],
        "product": order["product"],
        "quantity": order["quantity"],
        "price": order["price"],
        "status": order["status"],
    }

# Create Order (status set automatically)
@app.post("/orders", response_model=dict)
async def create_order(order: OrderBooking):
    order_data = order.dict()
    order_data["status"] = "Order Placed"   # backend-enforced status
    new_order = await orders_collection.insert_one(order_data)
    created_order = await orders_collection.find_one({"_id": new_order.inserted_id})
    return order_helper(created_order)

# Read Order
@app.get("/orders/{order_id}", response_model=dict)
async def get_order(order_id: str):
    order = await orders_collection.find_one({"_id": ObjectId(order_id)})
    if order:
        return order_helper(order)
    raise HTTPException(status_code=404, detail="Order not found")

# Update Order (status can be updated internally if needed)
@app.put("/orders/{order_id}", response_model=dict)
async def update_order(order_id: str, order: OrderUpdate):
    existing_order = await orders_collection.find_one({"_id": ObjectId(order_id)})
    if not existing_order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Build update dict: only apply fields that are not default placeholders
    update_data = {}
    if order.customer_name != "":
        update_data["customer_name"] = order.customer_name
    if order.product != "":
        update_data["product"] = order.product
    if order.quantity != 0:
        update_data["quantity"] = order.quantity
    if order.price != 0.0:
        update_data["price"] = order.price
    update_data["status"] = "Order Updated"
    if update_data:
        await orders_collection.update_one(
            {"_id": ObjectId(order_id)}, {"$set": update_data}
        )

    updated_order = await orders_collection.find_one({"_id": ObjectId(order_id)})
    return order_helper(updated_order)

# Delete Order
@app.delete("/orders/{order_id}", response_model=dict)
async def delete_order(order_id: str):
    delete_result = await orders_collection.delete_one({"_id": ObjectId(order_id)})
    if delete_result.deleted_count == 1:
        return {"message": "Order deleted successfully"}
    raise HTTPException(status_code=404, detail="Order not found")

# List Orders
@app.get("/orders", response_model=list)
async def list_orders():
    orders = []
    async for order in orders_collection.find():
        orders.append(order_helper(order))
    return orders
