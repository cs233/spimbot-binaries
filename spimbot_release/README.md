# How to work with spimbot

1. have docker daemon running

2. run the following command inside your terminal:

  ```sh
  docker compose pull 
  docker compose up -d
  ```

3. updating spimbot in your docker container
  
  The spimbot binary will be updated automatically when you open up a new terminal session, but if you wish to be extra safe, you can always run:

  ```sh
  update_spimbot
  ```
  
  manually to get the latest spimbot and test to see if your solution works as expected. The autograder will always use the latest version of spimbot.


4. submit your solution to PrairieLearn when you are ready :)
