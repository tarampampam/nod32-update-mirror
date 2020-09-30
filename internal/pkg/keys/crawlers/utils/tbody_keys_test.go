package utils

import (
	"nod32-update-mirror/internal/pkg/keys"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSimpleTBodyKeysExtract(t *testing.T) {
	html := `
<table class="table_eav">
	<thead>
	<tr><th colspan="3">
			<h3>ESET NOD32 Antivirus (EAV) 4-8</h3>
		</th></tr>
	</thead>
	<tbody id="block_keys1" class="keys_eav">
	<tr class="bgkeyhead">
		<td>Имя пользователя</td>
		<td>Пароль</td>
		<td>Истекает</td>
	</tr>
	<tr>
		<td id="first_name_eav" class="name" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="EAV-0263094078">EAV-0263094078</td>
		<td id="first_pass_eav" class="password" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="477r6sf2rc">477r6sf2rc</td>
		<td class="dexpired">07.01.2020</td>
	</tr>
	<tr>
		<td id="twice_name_eav" class="name" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="TRIAL-0263727323">TRIAL-0263727323</td>
		<td id="twice_pass_eav" class="password" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="s76xh9bm5s">s76xh9bm5s</td>
		<td class="dexpired">24.10.2019</td>
	</tr>
	</tbody>
</table>
<table class="table_eis double">
	<thead>
	<tr><th colspan="3">
			<h3>ESET Smart Security (ESS) 9-12</h3>
		</th></tr>
	</thead>
	<tbody id="block_keys5" class="keys_eis">
	<tr class="bgkeyhead">
		<td colspan="2">Лицензионный ключ</td>
		<td>Истекает</td>
	</tr>
	<tr>
		<td id="first_big_smart910" class="password" colspan="2" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="CC66-XA55-MBCM-N9NE-PAA8">CC66-XA55-MBCM-N9NE-PAA8</td>
		<td class="dexpired">15.12.2019</td>
	</tr>
	<tr>
		<td id="twice_big_smart910" class="password" colspan="2" data-tooltip="Нажмите, чтобы скопировать"
data-clipboard-text="VND8-W333-794S-SNCR-M3AD">VND8-W333-794S-SNCR-M3AD</td>
		<td class="dexpired">10.04.2020</td>
	</tr>
	</tbody>
</table>
<table class="table_essp"><thead><tr><th>
		<h3>ESET Smart Security Premium 10-12</h3>
	</th></tr></thead><tbody id="block_keys4" class="keys_essp">
<tr><td id="firstPremium10" class="password" colspan="2">9VJ9-X9XR-UBDH-4AC6-GXHD</td>
</tr><tr><td id="twicePremium10" class="password" colspan="2">578B-X7WD-X9PA-C54S-CNTN</td>
</tr></tbody></table>
`

	result1, err := SimpleTBodyKeysExtract(html, "block_keys1", []keys.KeyType{keys.KeyTypeEAVv4, keys.KeyTypeEAVv5})
	assert.NoError(t, err)

	assert.Len(t, *result1, 2)
	assert.Contains(t, *result1, keys.Key{
		ID:             "EAV-0263094078",
		Password:       "477r6sf2rc",
		Types:          []keys.KeyType{keys.KeyTypeEAVv4, keys.KeyTypeEAVv5},
		ExpiringAtUnix: 1578355200,
	})
	assert.Contains(t, *result1, keys.Key{
		ID:             "TRIAL-0263727323",
		Password:       "s76xh9bm5s",
		Types:          []keys.KeyType{keys.KeyTypeEAVv4, keys.KeyTypeEAVv5},
		ExpiringAtUnix: 1571875200,
	})

	result2, err := SimpleTBodyKeysExtract(html, "block_keys5", []keys.KeyType{keys.KeyTypeESSv9})
	assert.NoError(t, err)

	assert.Len(t, *result2, 2)
	assert.Contains(t, *result2, keys.Key{
		ID:             "CC66-XA55-MBCM-N9NE-PAA8",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeESSv9},
		ExpiringAtUnix: 1576368000,
	})
	assert.Contains(t, *result2, keys.Key{
		ID:             "VND8-W333-794S-SNCR-M3AD",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeESSv9},
		ExpiringAtUnix: 1586476800,
	})

	result3, err := SimpleTBodyKeysExtract(html, "block_keys4", []keys.KeyType{keys.KeyTypeESSPv10})
	assert.NoError(t, err)

	assert.Len(t, *result3, 2)
	assert.Contains(t, *result3, keys.Key{
		ID:             "9VJ9-X9XR-UBDH-4AC6-GXHD",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeESSPv10},
		ExpiringAtUnix: 0,
	})
	assert.Contains(t, *result3, keys.Key{
		ID:             "578B-X7WD-X9PA-C54S-CNTN",
		Password:       "",
		Types:          []keys.KeyType{keys.KeyTypeESSPv10},
		ExpiringAtUnix: 0,
	})
}
