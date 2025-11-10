#lightweight Python base image
FROM python:3.10-slim

#set the working directory inside the container
WORKDIR /app

#copy dependency file and install packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

#copy the application code
COPY app/ ./app

#Expose the port that the app will run on
EXPOSE 8080

#Run the FastAPI app with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
