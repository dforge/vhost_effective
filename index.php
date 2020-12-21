<?php
    $db_host    = "localhost";
    $db_user    = "cddbuser";
    $db_pass    = "cddbpass";
    $db_name    = "cddbuser";

    $connection = mysqli_connect($db_host,$db_user,$db_pass,$db_name);

    if (!$connection) {
        $version = phpversion();
        $db      = "Cannot connect";
        exit();
    }

    $version = phpversion();
    $db      = "Connected";
?>
<!DOCTYPE html>
<html class="no-js" lang="">
    <head>
        <meta charset="utf-8"/>
        <title><?php echo "Hello: ". $_SERVER['SERVER_NAME']; ?></title>
        <meta name="description" content=""/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link rel="stylesheet" href="https://unpkg.com/spectre.css/dist/spectre.min.css"/>
    </head>
    <body>
        <div class="container">
            <div class="columns">
                <div class="col-7 col-mx-auto">
                    <br/>
                    <br/>
                    <br/>
                    <img class="p-centered" src="/picme.png"/>
                    <p class="text-center h1 text-primary"><?php echo $_SERVER['SERVER_NAME']; ?></p>
                    <p class="text-center h5"><?php echo "database status is: ".$db; ?></p>
                    <p class="text-center"><?php echo "installed php version is: ". $version; ?></p>
                    <br/>
                    <p class="text-center text-small text-lowercase text-gray">2020 &copy; hello plumbear!</a>
                </div>
            </div>
        </div>
    </body>
</html>