/**
* A task runner to automate the creation of image thumbnails of all images in a directory.

* "imagePath" argument is required. This is where the original images are found.
* "thumbnailPath" argument is optional. This is where the thumbnails will be created. Defaults to a directory named "thumbnails" inside the "imagePath".
* "thumbnailWidth" argument is optional. Defaults to 150.
* To run, use command "task run :imagePath={path}".
*/

component accessors="true" {

    property name="imagePath";
    property name="thumbnailPath";
    property name="thumbnailWidth" type="numeric";

    public function run(required string imagePath, string thumbnailPath, numeric thumbnailWidth = 150) {

        setImagePath(arguments.imagePath);
        if (!directoryExists(getImagePath())) {
            print.redLine("Specified image path " & getImagePath() & " does not exist.");
            return;
        }
        if (!arguments.keyExists("thumbnailPath")) {
            setThumbnailPath(getImagePath() & "/thumbnails");
            if (!directoryExists(getThumbnailPath())) {
                directoryCreate(getThumbnailPath());
            }
        } else if (!directoryExists(arguments.thumbnailPath)) {
            print.redLine("Specified thumbnail path " & getImagePath() & " does not exist.");
            return;
        } else {
            setThumbnailPath(arguments.thumbnailPath);
        }
        setThumbnailWidth(arguments.thumbnailWidth);

        scanImagePath();
        startWatcher();
    }

    private void function scanImagePath() {
        // Get lists of existing files
        var imageFiles = directoryList(path=getImagePath(), listInfo="name", filter="*.jpg|*.jpeg|*.gif|*.png", type="file");
        var thumbnailFiles = directoryList(path=getThumbnailPath(), listInfo="name", filter="*.jpg|*.jpeg|*.gif|*.png", type="file");

        // Remove files that already have thumbnails
        imageFiles = imageFiles.filter(function(file){
            return !thumbnailFiles.findNoCase(file);
        });
        // Create a thumbnail for remaining files
        imageFiles.each(createThumbnail);
    }

    private void function startWatcher() {
        watch()
        .paths("**.jpg","**.jpeg","**.gif","**.png")
        .inDirectory(getImagePath())
            .withDelay(5000)
            .onChange(function(paths) {
                paths.added.each(createThumbnail);
                paths.changed.each(createThumbnail);
            })
            .start();
    }

    private void function createThumbnail(required string fileName) {
        local.imagePath = getImagePath() & "/" & arguments.fileName;
        local.thumbnailPath = getThumbnailPath() & "/" & arguments.fileName;
        if (!fileExists(local.imagePath)) {
            print.redLine(arguments.fileName & " does not exist.").toConsole();
            return;
        } else if (!isImageFile(local.imagePath)) {
            print.yellowLine(arguments.fileName & " is not an image.").toConsole();
            return;
        }

        try {
            local.image = imageRead(local.imagePath);
            local.image.resize(getThumbnailWidth());
            local.image.write(local.thumbnailPath);
            print.greenLine(arguments.fileName & " created.").toConsole();
        } catch (any e) {
            print.redLine(arguments.fileName & " could not be created. " & e.message).toConsole();
        }
    }

}
