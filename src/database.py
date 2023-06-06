import pymysql
import os
from dotenv import load_dotenv

from datetime import datetime
from sqlalchemy import insert
from models import ChurnRequest, ChurnPrediction
from sqlmodel import create_engine, SQLModel
from sqlalchemy.orm import Session  

load_dotenv()   

SQLALCHEMY_DATABASE_URL = os.getenv('SQLALCHEMY_DATABASE_URL')
# print(SQLALCHEMY_DATABASE_URL)

engine = create_engine(SQLALCHEMY_DATABASE_URL, echo=True) 

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)


def get_db():
    db = Session(engine)
    try:
        yield db
    finally:
        db.close()





# RDS mysql connection
def get_mysql_conn(): 
    conn = pymysql.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT")),
        user=os.getenv("DB_USER"),
        passwd=os.getenv("DB_PASSWORD"),
        db=os.getenv("DB_DATABASE"),
        charset='utf8mb4')
    return conn

def insert_request_to_db(request, prediction, client_ip, db): 
    # insert request
    request = ChurnRequest(**request)
    db.add(request)
    db.commit()
    db.refresh(request)
    # insert prediction
    prediction = ChurnPrediction(churn_request_id=request.id, prediction=prediction, client_ip=client_ip)
    db.add(prediction)
    db.commit()
    db.refresh(prediction)
    return prediction
 

 