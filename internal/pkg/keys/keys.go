package keys

// Key is a basic struct, that describes the key
type (
	Key struct {
		// ID (EAV-0123456789) or License key (XXXX-XXXX-XXXX-XXXX-XXXX)
		ID string `json:"id"`

		// Password for ID (node: for license keys password is empty)
		Password string `json:"password,omitempty"`

		// Key types
		Types []KeyType `json:"types"`

		// When key was added
		AddedAtUnix int64 `json:"added_at_unix,omitempty"`

		// When key will be expired
		ExpiringAtUnix int64 `json:"expiring_at_unix,omitempty"`
	}

	// Keys is a set of keys
	Keys []Key

	// KeyType is a key type
	KeyType string
)

const (
	KeyTypeESSv4  = "ESSv4"  // NOD32 Smart Security v4 (id:password)
	KeyTypeESSv5  = "ESSv5"  // NOD32 Smart Security v5 (id:password)
	KeyTypeESSv6  = "ESSv6"  // NOD32 Smart Security v6 (id:password)
	KeyTypeESSv7  = "ESSv7"  // NOD32 Smart Security v7 (id:password)
	KeyTypeESSv8  = "ESSv8"  // NOD32 Smart Security v8 (id:password)
	KeyTypeESSv9  = "ESSv9"  // NOD32 Smart Security v9 (license key)
	KeyTypeESSv10 = "ESSv10" // NOD32 Smart Security v10 (license key)
	KeyTypeESSv11 = "ESSv11" // NOD32 Smart Security v11 (license key)
	KeyTypeESSv12 = "ESSv12" // NOD32 Smart Security v12 (license key)

	KeyTypeEAVv4  = "EAVv4"  // NOD32 Antivirus v4 (id:password)
	KeyTypeEAVv5  = "EAVv5"  // NOD32 Antivirus v5 (id:password)
	KeyTypeEAVv6  = "EAVv6"  // NOD32 Antivirus v6 (id:password)
	KeyTypeEAVv7  = "EAVv7"  // NOD32 Antivirus v7 (id:password)
	KeyTypeEAVv8  = "EAVv8"  // NOD32 Antivirus v8 (id:password)
	KeyTypeEAVv9  = "EAVv9"  // NOD32 Antivirus v9 (license key)
	KeyTypeEAVv10 = "EAVv10" // NOD32 Antivirus v10 (license key)
	KeyTypeEAVv11 = "EAVv11" // NOD32 Antivirus v11 (license key)
	KeyTypeEAVv12 = "EAVv12" // NOD32 Antivirus v12 (license key)

	KeyTypeEISv10 = "EISv10" // NOD32 Internet Security v10 (license key)
	KeyTypeEISv11 = "EISv11" // NOD32 Internet Security v11 (license key)
	KeyTypeEISv12 = "EISv12" // NOD32 Internet Security v12 (license key)

	KeyTypeEISPv10 = "EISPv10" // NOD32 Internet Security Premium v10 (license key)
	KeyTypeEISPv11 = "EISPv11" // NOD32 Internet Security Premium v11 (license key)
	KeyTypeEISPv12 = "EISPv12" // NOD32 Internet Security Premium v12 (license key)
)

// String return key type in a string representation.
func (k KeyType) String() string { return string(k) }
