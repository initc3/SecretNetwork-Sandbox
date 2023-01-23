package keeper

import (
	"fmt"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/scrtlabs/SecretNetwork/x/compute/internal/types"
)

type DummyStore struct {
	real_store    sdk.KVStore
	dummy_store   sdk.KVStore
	snapshot_name string
	// updated_keys  []string
	// map_dummy_store map[string][]byte
}

func NewDummyStore(
	real_store sdk.KVStore,
	contractAddress sdk.AccAddress,
	snapshot_name string,
) DummyStore {
	prefixStoreKey := types.GetContractStorePrefixKey(contractAddress)
	dummy_prefixStoreKey := append([]byte(snapshot_name), prefixStoreKey...)
	dummy_prefixStore := prefix.NewStore(real_store, dummy_prefixStoreKey)
	fmt.Printf("x/compute/internal/keeper/dummy_store.go NewDummyStore snapshot_name: |%s|\n", snapshot_name)
	return DummyStore{real_store, dummy_prefixStore, snapshot_name}
}

func (d DummyStore) Get(key []byte) []byte {
	fmt.Printf("x/compute/internal/keeper/dummy_store.go Get snapshot_name: |%s|\n", d.snapshot_name)
	if d.snapshot_name == "" {
		return d.real_store.Get(key)
	} else {
		if d.dummy_store.Has(key) { //the value was set in dummy_store so return that value
			return d.dummy_store.Get(key)
		} else { //value was not set in dummy_store so get it from the real store and update it to dummy_store
			v := d.real_store.Get(key)
			d.dummy_store.Set(key, v)
			return v
		}
	}
}

func (d DummyStore) Has(key []byte) bool {
	if d.snapshot_name == "" {
		return d.dummy_store.Has(key)
	} else {
		return d.real_store.Has(key)
	}
}

func (d DummyStore) Set(key, value []byte) {
	fmt.Printf("x/compute/internal/keeper/dummy_store.go Set snapshot_name |%s|\n", d.snapshot_name)
	if d.snapshot_name == "" {
		d.real_store.Set(key, value)
	} else {
		d.dummy_store.Set(key, value)
	}
}

func (d DummyStore) Delete(key []byte) {
	if d.snapshot_name == "" {
		d.real_store.Delete(key)
	} else {
		if d.real_store.Has(key) && !d.dummy_store.Has(key) {
			return //prevent panic from delete value in real store but not in dummy_store
		}
		d.dummy_store.Delete(key)
	}
}

// todo
func (d DummyStore) Iterator(start, end []byte) sdk.Iterator {
	if d.snapshot_name == "" {
		return d.real_store.Iterator(start, end)
	} else {
		return d.dummy_store.Iterator(start, end)
	}
}

func (d DummyStore) ReverseIterator(start, end []byte) sdk.Iterator {
	if d.snapshot_name == "" {
		return d.real_store.ReverseIterator(start, end)
	} else {
		return d.dummy_store.ReverseIterator(start, end)
	}
}
