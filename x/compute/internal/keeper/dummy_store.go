package keeper

import (
	"fmt"
	"os"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

type DummyStore struct {
	real_store 	sdk.KVStore
	// set_keys	[][]byte
}

func NewDummyStore(
	real_store sdk.KVStore,
) DummyStore {
	return DummyStore{ real_store }
}

func (d DummyStore) Get(key []byte) []byte {
	return d.real_store.Get(key)
}

func (d DummyStore) Has(key []byte) bool {
	// if contains(d.set_keys) {
	// 	return true
	// }
	return d.real_store.Has(key)
}


func (d DummyStore) Set(key, value []byte) {
	fmt.Println("x/compute/internal/keeper/dummy_store.go Set DUMMY_STORE: %s", os.Getenv("DUMMY_STORE"))
	if os.Getenv("DUMMY_STORE") != "true" {
		fmt.Println("x/compute/internal/keeper/dummy_store.go Set setting in real store key %+x value %+x", key, value)
		d.real_store.Set(key, value)
	} else {
		// d.set_keys = d.set_keys, key)
		fmt.Println("x/compute/internal/keeper/dummy_store.go Set NOT setting key %+x value %+x", key, value)
	}
}

func (d DummyStore) Delete(key []byte) {
	d.real_store.Delete(key)
}

func (d DummyStore) Iterator(start, end []byte) sdk.Iterator {
	return d.real_store.Iterator(start, end)
}

func (d DummyStore) ReverseIterator(start, end []byte) sdk.Iterator {
	return d.real_store.ReverseIterator(start, end)
}

// func contains(s [][]byte, str []byte) bool {
// 	for _, v := range s {
// 		if v == str {
// 			return true
// 		}
// 	}

// 	return false
// }