from fastapi import FastAPI, Depends, Request
from sqlalchemy.orm import Session 
from models import CreateUpdateChurn, Churn 
from config import load_model_from_s3, get_db 

## Load Model

model = load_model_from_s3()
 
app = FastAPI() 

## Endpoints ######
@app.get("/")
def root_endpoint():
    return {"message": "Hello Churn Prediction API!"}

 
@app.post("/prediction/churn")
async def predict_churn(request: CreateUpdateChurn,
                        fastapi_req: Request,
                        db: Session = Depends(get_db) 
                         ) -> dict:
    prediction = make_churn_prediction(model, request.dict())   
    inserted_record = insert_request_to_db(request=request.dict(),prediction=prediction,client_ip=fastapi_req.client.host,db=db)
    return  {"inserted_record": inserted_record}



## functions #####
def make_churn_prediction(model, request):
    #parse input from the request
    creditScore = request["creditScore"]
    geography = request['geography']
    gender = request['gender']
    age = request['age']
    tenure = request['tenure']
    balance = request['balance']
    numOfProducts = request['numOfProducts']
    hasCrCard = request['hasCrCard']
    isActiveMember = request['isActiveMember']
    estimatedSalary = request['estimatedSalary']
    
    # Make an input vector
    person = [[creditScore, geography, gender, age, tenure, balance, numOfProducts, hasCrCard, isActiveMember, estimatedSalary]]
    
    # Predict
    prediction = model.predict(person) 
    return prediction[0]


def insert_request_to_db (request, prediction, client_ip, db):
    new_churn = Churn(
        creditScore=request["creditScore"],
        geography=request['geography'],
        age = request['age'],
        tenure = request['tenure'],
        balance = request['balance'],
        numOfProducts = request['numOfProducts'],
        hasCrCard = request['hasCrCard'],
        isActiveMember = request['isActiveMember'],
        estimatedSalary = request['estimatedSalary'],
        prediction=prediction,
        client_ip=client_ip
    )

    with db as session:
        session.add(new_churn)
        session.commit()
        session.refresh(new_churn)

    return new_churn
