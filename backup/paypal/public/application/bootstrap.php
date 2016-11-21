<?php

// подключаем файлы ядра
require_once 'core/model.php';
require_once 'core/view.php';
require_once 'core/controller.php';


// Slim initialization ////////////////////////////////////
require __DIR__ . './../../vendor/autoload.php';

session_start();

// Instantiate the app
$settings = require __DIR__ . './../../src/settings.php';
$app = new \Slim\App($settings);

// Set up dependencies
require __DIR__ . './../../src/dependencies.php';

// Register middleware
require __DIR__ . './../../src/middleware.php';

// Register routes
require __DIR__ . './../../src/routes.php';

////////////////////////////////////////////////////////////

//require_once 'core/route.php';
//Route::start(); // запускаем маршрутизатор

// Run app
$app->run();