package keeper

import (
	"fmt"
	"os"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

type DummyStore struct {
	real_store 	sdk.KVStore
	dummy_store	map[string][]byte
}

func NewDummyStore(
	real_store sdk.KVStore,
) DummyStore {
	m := make(map[string][]byte)
	return DummyStore{ real_store, m}
}

func (d DummyStore) Get(key []byte) []byte {
	if os.Getenv("DUMMY_STORE") != "true" {
		return d.real_store.Get(key)
	} else {
		val, ok := d.dummy_store[string(key)]
		if ok {
			return val 
		} else {
			return []byte{}
		}
	}
}

func (d DummyStore) Has(key []byte) bool {
	if os.Getenv("DUMMY_STORE") != "true" {
		_, ok := d.dummy_store[string(key)]
		return ok
	} else {
		return d.real_store.Has(key)
	}
}


func (d DummyStore) Set(key, value []byte) {
	fmt.Println("x/compute/internal/keeper/dummy_store.go Set DUMMY_STORE: %s", os.Getenv("DUMMY_STORE"))
	if os.Getenv("DUMMY_STORE") != "true" {
		fmt.Println("x/compute/internal/keeper/dummy_store.go Set setting in real store key %+x value %+x", key, value)
		d.real_store.Set(key, value)
	} else {
		fmt.Println("x/compute/internal/keeper/dummy_store.go Set NOT setting key %+x value %+x", key, value)
		d.dummy_store[string(key)] = value
	}
}

func (d DummyStore) Delete(key []byte) {
	if os.Getenv("DUMMY_STORE") != "true" {
		d.real_store.Delete(key)
	} else {
		delete(d.dummy_store, string(key))
	}
}

func (d DummyStore) Iterator(start, end []byte) sdk.Iterator {
	return d.real_store.Iterator(start, end)
}

func (d DummyStore) ReverseIterator(start, end []byte) sdk.Iterator {
	return d.real_store.ReverseIterator(start, end)
}