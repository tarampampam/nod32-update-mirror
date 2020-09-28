package main

import (
	"fmt"
	mainCmd "nod32-update-mirror/internal/pkg/cmd/nod32-mirror"
	"os"
	"path/filepath"
)

func main() {
	cmd := mainCmd.NewCommand(filepath.Base(os.Args[0]))

	if err := cmd.Execute(); err != nil {
		if _, outErr := fmt.Fprintf(os.Stderr, "An error occurred: %v\n", err); outErr != nil {
			panic(outErr)
		}

		os.Exit(1)
	}
}
