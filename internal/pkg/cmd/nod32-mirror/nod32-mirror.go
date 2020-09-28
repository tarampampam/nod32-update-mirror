package nod32_mirror //nolint:golint,stylecheck

import (
	"nod32-update-mirror/internal/pkg/cmd/cli/flush"
	"nod32-update-mirror/internal/pkg/cmd/cli/key"
	"nod32-update-mirror/internal/pkg/cmd/cli/serve"
	"nod32-update-mirror/internal/pkg/cmd/cli/stat"
	"nod32-update-mirror/internal/pkg/cmd/cli/update"
	"nod32-update-mirror/internal/pkg/cmd/cli/version"

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
	cmd := &cobra.Command{
		Use:   name,
		Short: "ESET Nod32 Updates Mirror",
		Long:  banner,
	}

	cmd.AddCommand(
		version.NewCommand(),
		update.NewCommand(),
		flush.NewCommand(),
		serve.NewCommand(),
		key.NewCommand(),
		stat.NewCommand(),
	)

	return cmd
}
