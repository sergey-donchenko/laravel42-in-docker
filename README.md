# laravel42-in-docker
Development environment for Laravel 4.2 in Docker Container 

Tested on MacOS/M4 with Docker Desktop installed

In order to run the pre-build script, make sure the `.env` file is prepared and placed in the root of the project.
To simplify that, just copy the `.env` from example, so, run the following command:

 `cp .env.example ./src/.env`

The next step is running the building process for the container and its related services such as Apache and MySQL

`npm run build_and_start_dev_env`