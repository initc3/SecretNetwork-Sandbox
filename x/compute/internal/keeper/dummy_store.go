package keeper

import (
	"fmt"

	"github.com/cosmos/cosmos-sdk/store/prefix"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

type DummyStore struct {
	real_store    sdk.KVStore
	dummy_store   sdk.KVStore
	snapshot_name string
	map_dummy_store map[string][]byte
}

func NewDummyStore(
	parent_store sdk.KVStore,
	prefixStoreKey []byte,
	snapshot_name string,
	kvmap map[string][]byte,
) DummyStore {
	real_store := prefix.NewStore(parent_store, prefixStoreKey)
	dummy_prefixStoreKey := append([]byte(snapshot_name), prefixStoreKey...)
	dummy_prefixStore := prefix.NewStore(parent_store, dummy_prefixStoreKey)
	fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go NewDummyStore snapshot_name: |%s| prefixStoreKey: |%x|\n", snapshot_name, prefixStoreKey)
	return DummyStore{real_store, dummy_prefixStore, snapshot_name, kvmap}
}

func (d DummyStore) Get(key []byte) []byte {
	fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Get snapshot_name: |%s| key %x\n", d.snapshot_name, key)
	// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Get dummy_store %v\n", d.map_dummy_store)
	if d.snapshot_name == "" {
		return d.real_store.Get(key)
	} else {
		v, ok := d.map_dummy_store[d.snapshot_name + string(key)]
		// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Get setting key in map %s\n", d.snapshot_name + string(key))
		if ok { //the value was set in dummy_store so return that value
			return v
		} else { //value was not set in dummy_store so get it from the real store and update it to dummy_store
			// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Get snapshot_name: |%s| key %x not in dummy_store getting from real_store\n", d.snapshot_name, key)
			v := d.real_store.Get(key)
			// d.map_dummy_store[d.snapshot_name + string(key)] = v

			return v
		}
	}
}

func (d DummyStore) Has(key []byte) bool {
	// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Has snapshot_name |%s| key %x\n", d.snapshot_name, key)
	if d.snapshot_name == "" {
		return d.real_store.Has(key)
	} else {
		_, ok := d.map_dummy_store[d.snapshot_name + string(key)]
		if !ok {
			return d.real_store.Has(key)
		}
		return false
	}
}

func (d DummyStore) Set(key, value []byte) {
	fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Set snapshot_name |%s| key %x value %x\n", d.snapshot_name, key, value)
	// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Set dummy_store %v\n", d.map_dummy_store)
	if d.snapshot_name == "" {
		d.real_store.Set(key, value)
	} else {
		//fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Set setting key in map %s\n", d.snapshot_name + string(key))
		d.map_dummy_store[d.snapshot_name + string(key)] = value
		// fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Set after dummy_store %v\n", d.map_dummy_store)
	}
}

func (d DummyStore) Delete(key []byte) {
	fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Delete snapshot_name |%s| key %x\n", d.snapshot_name, key)
	if d.snapshot_name == "" {
		d.real_store.Delete(key)
	} else {
		if d.real_store.Has(key) && !d.dummy_store.Has(key) {
			return //prevent panic from delete value in real store but not in dummy_store
		}
		delete(d.map_dummy_store, d.snapshot_name + string(key))
	}
}

// todo
func (d DummyStore) Iterator(start, end []byte) sdk.Iterator {
	fmt.Printf("cypherpunk x/compute/internal/keeper/dummy_store.go Iterator snapshot_name |%s|\n", d.snapshot_name)
	// if d.snapshot_name == "" {
		return d.real_store.Iterator(start, end)
	// } else {
	// 	return d.dummy_store.Iterator(start, end)
	// }
}

func (d DummyStore) ReverseIterator(start, end []byte) sdk.Iterator {
	// if d.snapshot_name == "" {
		return d.real_store.ReverseIterator(start, end)
	// } else {
		// return d.dummy_store.ReverseIterator(start, end)
	// }
}
