package keeper

import (
	"fmt"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/scrtlabs/SecretNetwork/x/compute/internal/types"
)

type DummyStore struct {
	real_store      sdk.KVStore
	dummy_store     sdk.KVStore
	snapshot_name	string
	map_dummy_store map[string][]byte
}

func NewDummyStore(
	real_store sdk.KVStore,
	contractAddress sdk.AccAddress,
	snapshot_name	string,
) DummyStore {
	map_dummy_store := make(map[string][]byte)
	prefixStoreKey := types.GetContractStorePrefixKey(contractAddress)
	dummy_prefixStoreKey := append([]byte(snapshot_name), prefixStoreKey...)
	dummy_prefixStore := prefix.NewStore(real_store, dummy_prefixStoreKey)
	fmt.Printf("x/compute/internal/keeper/dummy_store.go NewDummyStore snapshot_name: |%s|\n", snapshot_name)

	return DummyStore{real_store, dummy_prefixStore, snapshot_name, map_dummy_store}
}

func (d DummyStore) Get(key []byte) []byte {
	fmt.Printf("x/compute/internal/keeper/dummy_store.go Get snapshot_name: |%s|\n", d.snapshot_name)
	if d.snapshot_name == "" {
		return d.real_store.Get(key)
	} else {
		// val, ok := d.map_dummy_store[string(key)]
		// if ok {
		// 	return val
		// } else {
		// 	return nil
		// }
		return d.dummy_store.Get(key)
	}
}

func (d DummyStore) Has(key []byte) bool {
	if d.snapshot_name == "" {
		// _, ok := d.map_dummy_store[string(key)]
		// return ok
		return d.dummy_store.Has(key)
	} else {
		return d.real_store.Has(key)
	}
}

func (d DummyStore) Set(key, value []byte) {
	fmt.Printf("x/compute/internal/keeper/dummy_store.go Set snapshot_name |%s|\n", d.snapshot_name)
	if d.snapshot_name == "" {
		fmt.Printf("x/compute/internal/keeper/dummy_store.go Set setting in real store key %+x value %+x\n", key, value)
		d.real_store.Set(key, value)
	} else {
		fmt.Printf("x/compute/internal/keeper/dummy_store.go Set NOT setting key %+x value %+x\n", key, value)
		// d.map_dummy_store[string(key)] = value
		d.dummy_store.Set(key, value)
	}
}

func (d DummyStore) Delete(key []byte) {
	if d.snapshot_name == "" {
		d.real_store.Delete(key)
	} else {
		// delete(d.map_dummy_store, string(key))
		d.dummy_store.Delete(key)
	}
}

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
