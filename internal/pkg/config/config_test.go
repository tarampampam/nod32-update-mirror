package config

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestFromYaml(t *testing.T) {
	var cases = []struct {
		name          string
		giveYaml      []byte
		giveExpandEnv bool
		giveEnv       map[string]string
		wantErr       bool
		checkResultFn func(*testing.T, *Config)
		wantConfig    *Config
	}{
		{
			name:          "Using full yaml",
			giveExpandEnv: true,
			giveYaml: []byte(`
mirror:
  path: /tmp/foobar
  servers:
    - url: 'https://example.com:445/bar'
      username: EAV-1122334455
      password: aabbccddee
  free-keys:
    enabled: true
    file-path: '/tmp/keys.dat'
  filtering:
    platforms: [any, foo]
    types: [any, bar]
    languages: [1033, 9999]
    versions: [foo, 1, 999]
downloading:
  threads: 5
  max-speed-kb: 223344
http:
  listen: '0.0.0.0:8080'
  basic-auth:
    enabled: true
    users:
      - username: evil
        password: live
`),
			wantErr: false,
			checkResultFn: func(t *testing.T, config *Config) {
				assert.Equal(t, "/tmp/foobar", config.Mirror.Path)

				assert.Equal(t, "https://example.com:445/bar", config.Mirror.Servers[0].URL)
				assert.Equal(t, "EAV-1122334455", config.Mirror.Servers[0].Username)
				assert.Equal(t, "aabbccddee", config.Mirror.Servers[0].Password)

				assert.True(t, config.Mirror.FreeKeys.Enabled)
				assert.Equal(t, "/tmp/keys.dat", config.Mirror.FreeKeys.FilePath)

				assert.Equal(t, []string{"any", "foo"}, config.Mirror.Filtering.Platforms)
				assert.Equal(t, []string{"any", "bar"}, config.Mirror.Filtering.Types)
				assert.Equal(t, []string{"1033", "9999"}, config.Mirror.Filtering.Languages)
				assert.Equal(t, []string{"foo", "1", "999"}, config.Mirror.Filtering.Versions)

				assert.Equal(t, uint16(5), config.Downloading.Threads)
				assert.Equal(t, uint32(223344), config.Downloading.MaxSpeedKB)

				assert.Equal(t, "0.0.0.0:8080", config.HTTP.Listen)
				assert.True(t, config.HTTP.BasicAuth.Enabled)
				assert.Equal(t, "evil", config.HTTP.BasicAuth.Users[0].Username)
				assert.Equal(t, "live", config.HTTP.BasicAuth.Users[0].Password)
			},
		},
		{
			name:          "ENV variables expanded",
			giveExpandEnv: true,
			giveEnv:       map[string]string{"__TEST_MIRROR_PATH": "/tmp/bar", "__TEST_MIRROR_USE_FREE_KEY": "true"},
			giveYaml: []byte(`
mirror:
  path: ${__TEST_MIRROR_PATH}
  free-keys:
    enabled: ${__TEST_MIRROR_USE_FREE_KEY}
`),
			wantErr: false,
			checkResultFn: func(t *testing.T, config *Config) {
				assert.Equal(t, "/tmp/bar", config.Mirror.Path)
				assert.True(t, config.Mirror.FreeKeys.Enabled)
			},
		},
		{
			name:          "ENV variables NOT expanded",
			giveExpandEnv: false,
			giveYaml: []byte(`
mirror:
  path: ${__TEST_MIRROR_PATH}
`),
			wantErr: false,
			checkResultFn: func(t *testing.T, config *Config) {
				assert.Equal(t, "${__TEST_MIRROR_PATH}", config.Mirror.Path)
			},
		},
		{
			name:          "ENV variables defaults",
			giveExpandEnv: true,
			giveYaml: []byte(`
mirror:
  path: ${__TEST_MIRROR_PATH:-/tmp/baz}
  free-keys:
    enabled: ${__TEST_MIRROR_USE_FREE_KEY:-true}
`),
			wantErr: false,
			checkResultFn: func(t *testing.T, config *Config) {
				assert.Equal(t, "/tmp/baz", config.Mirror.Path)
				assert.True(t, config.Mirror.FreeKeys.Enabled)
			},
		},
		{
			name:     "broken yaml",
			giveYaml: []byte(`foo bar`),
			wantErr:  true,
		},
	}

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			if tt.giveEnv != nil {
				for key, value := range tt.giveEnv {
					assert.NoError(t, os.Setenv(key, value))
				}
			}

			conf, err := FromYaml(tt.giveYaml, tt.giveExpandEnv)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.Nil(t, err)
				tt.checkResultFn(t, conf)
			}

			if tt.giveEnv != nil {
				for key := range tt.giveEnv {
					assert.NoError(t, os.Unsetenv(key))
				}
			}
		})
	}
}

func TestFromYamlFile(t *testing.T) {
	var cases = []struct {
		name          string
		giveYaml      []byte
		giveExpandEnv bool
		wantError     bool
		checkResultFn func(*testing.T, *Config)
	}{
		{
			name:          "Using correct yaml",
			giveExpandEnv: true,
			giveYaml: []byte(`
mirror:
  path: '/tmp/foobar'
  free-keys:
    enabled: false
`),
			checkResultFn: func(t *testing.T, config *Config) {
				assert.Equal(t, "/tmp/foobar", config.Mirror.Path)
				assert.False(t, config.Mirror.FreeKeys.Enabled)
			},
		},
		{
			name:          "Using broken file (wrong format)",
			giveExpandEnv: true,
			giveYaml:      []byte(`!foo bar`),
			wantError:     true,
		},
	}

	for _, tt := range cases {
		t.Run(tt.name, func(t *testing.T) {
			file, _ := ioutil.TempFile("", "unit-test-")

			defer func(t *testing.T, f *os.File) {
				assert.NoError(t, f.Close())
				assert.NoError(t, os.Remove(f.Name()))
			}(t, file)

			_, fileWritingErr := file.Write(tt.giveYaml)
			assert.NoError(t, fileWritingErr)

			conf, err := FromYamlFile(file.Name(), tt.giveExpandEnv)

			if tt.wantError {
				assert.NotNil(t, err)
			} else {
				assert.Nil(t, err)
				tt.checkResultFn(t, conf)
			}
		})
	}
}
