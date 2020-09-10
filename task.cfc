component accessors="true" {

    property name="imagePath";
    property name="thumbnailPath";

    public function run(required string imagePath, string thumbnailPath) {

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
            local.image.resize(150);
            local.image.write(local.thumbnailPath);
            print.greenLine(arguments.fileName & " created.").toConsole();
        } catch (any e) {
            print.redLine(arguments.fileName & " could not be created. " & e.message).toConsole();
        }
    }

}
