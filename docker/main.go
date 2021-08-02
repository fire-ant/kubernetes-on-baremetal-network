package main

import (
	"flag"
	"io/ioutil"
	"os/exec"
	"strings"

	"path/filepath"

	log "github.com/sirupsen/logrus"
	fsnotify "gopkg.in/fsnotify.v1"
)

const (
	TMP_DIR    = "/tmp/intfs"
	TARGET_DIR = "/etc/network/interfaces.d"
)

var (
	targetDir = flag.String("target", TARGET_DIR, "target directory to copy into")
	tmpDir    = flag.String("tmp", TMP_DIR, "temp directory to watch")
)

func sync_all() {
	log.Infof("synchoronizing all files")
	files, err := ioutil.ReadDir(*tmpDir)
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range files {
		if strings.HasPrefix(file.Name(), ".") {
			continue
		}
		_, err := exec.Command("cp", filepath.Join(*tmpDir, file.Name()), *targetDir).Output()
		if err != nil {
			log.Infof("failed to copy file %q : %s", file.Name(), err)
		}
	}

}

func main() {
	flag.Parse()
	sync_all()

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Panicf("Failed to initialise fsnotify: %s", err)
	}
	defer watcher.Close()

	log.Infof("Starting a watch on  %s", *tmpDir)
	if err := watcher.Add(*tmpDir); err != nil {
		log.Panicf("failed to watch %q: %s", tmpDir, err)
	}

	for {
		select {
		case e := <-watcher.Events:
			log.Infof("detected event %s", e)
			sync_all()

		case err := <-watcher.Errors:
			log.Infof("Received watcher.Error: %s", err)
		}
	}

}
