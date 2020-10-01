package cli

import (
	"errors"
	"io/ioutil"
	"nod32-update-mirror/internal/pkg/cli/flush"
	"nod32-update-mirror/internal/pkg/cli/keys"
	"nod32-update-mirror/internal/pkg/cli/serve"
	"nod32-update-mirror/internal/pkg/cli/stat"
	"nod32-update-mirror/internal/pkg/cli/update"
	"nod32-update-mirror/internal/pkg/config"
	"nod32-update-mirror/internal/pkg/version"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

// Application banner (generate own using <http://patorjk.com/software/taag/#p=display&f=Small&t=FooBar>)
const banner = `    _   __          __________      __  ____
   / | / /___  ____/ /__  /__ \    /  |/  (_)_____________  _____
  /  |/ / __ \/ __  / /_ <__/ /   / /|_/ / / ___/ ___/ __ \/ ___/
 / /|  / /_/ / /_/ /___/ / __/   / /  / / / /  / /  / /_/ / /
/_/ |_/\____/\__,_//____/____/  /_/  /_/_/_/  /_/   \____/_/`

// NewCommand creates `nod32-mirror` command.
func NewCommand(name string) *cobra.Command {
	var (
		cfg              *config.Config = &config.Config{}
		logger           *logrus.Logger = newLogger()
		cfgFilePath      string
		verbose, logJSON bool
	)

	cmd := &cobra.Command{
		Use:     name,
		Short:   "ESET Nod32 Updates Mirror",
		Long:    banner,
		Version: version.Version(),

		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			if verbose {
				logger.SetLevel(logrus.TraceLevel)
			}

			if logJSON {
				logger.SetFormatter(&logrus.JSONFormatter{})
			}

			cfgBytes, err := ioutil.ReadFile(cfgFilePath)
			if err != nil {
				return errors.New("could not open config file: " + err.Error())
			}

			if err := cfg.FromYaml(cfgBytes, true); err != nil {
				return errors.New("could not parse config file: " + err.Error())
			}

			return nil
		},
	}

	cmd.PersistentFlags().StringVarP(&cfgFilePath, "config", "c", "./configs/config.yml", "config file")
	cmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	cmd.PersistentFlags().BoolVar(&logJSON, "log-json", false, "logs in JSON format")

	cmd.SilenceErrors = true
	cmd.SilenceUsage = true

	cmd.AddCommand(
		update.NewCommand(logger, cfg),
		flush.NewCommand(logger, cfg),
		serve.NewCommand(logger, cfg),
		keys.NewCommand(logger, cfg),
		stat.NewCommand(cfg),
	)

	return cmd
}

func newLogger() *logrus.Logger {
	l := logrus.New()

	l.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:          true,
		TimestampFormat:        "2006-01-02 15:04:05.000",
		DisableLevelTruncation: true,
	})

	return l
}
