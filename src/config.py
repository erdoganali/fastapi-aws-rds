import os 
import joblib  
from dotenv import load_dotenv
import boto3 
import logging
import tempfile
from sqlmodel import create_engine, SQLModel
from sqlalchemy.orm import Session   

load_dotenv() 

## BUCKET OPS
bucket = os.getenv("S3_BUCKET")
key = os.getenv("S3_KEY")
  
def get_s3_client():
    s3 = boto3.client(
                        "s3",
                        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
                        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
                        region_name=os.getenv("AWS_REGION")
                    )
    return s3 
    
def load_model_from_s3():
    ''' Read model from a s3 bucket'''
    s3_client = get_s3_client()
   # READ
    with tempfile.TemporaryFile() as fp:
        s3_client.download_fileobj(Fileobj=fp, Bucket=bucket, Key=key)
        fp.seek(0)
        model = joblib.load(fp)

    return model


## RDS MYSQL OPS    
  
DATABASE_USER = os.environ['DATABASE_USER']
DATABASE_PASSWORD = os.environ['DATABASE_PASSWORD']
DATABASE_HOST = os.environ['DATABASE_HOST']
DATABASE_PORT = os.environ['DATABASE_PORT']
DATABASE_NAME = os.environ['DATABASE_NAME']

DATABASE_URL = f"mysql+pymysql://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}/{DATABASE_NAME}"

engine = create_engine(DATABASE_URL)
SQLModel.metadata.create_all(engine)

def get_db():
    db = Session(engine)
    try:
        yield db
    finally:
        db.close()
 
