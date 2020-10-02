package main

import (
	"github.com/sirupsen/logrus"
	"nod32-update-mirror/internal/pkg/cli"
	"os"
	"path/filepath"
)

func main() {
	logger := logrus.New()

	logger.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:          true,
		TimestampFormat:        "2006-01-02 15:04:05.000",
		DisableLevelTruncation: true,
	})

	cmd := cli.NewCommand(logger, filepath.Base(os.Args[0]))

	if err := cmd.Execute(); err != nil {
		logger.Fatal(err)
	}
}
