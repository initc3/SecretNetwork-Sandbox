use cosmwasm_std::Storage;
use cosmwasm_storage::{singleton, singleton_read, ReadonlySingleton, Singleton};


pub const STORE1: &[u8] = b"test-1";
pub const STORE2: &[u8] = b"test-2";

pub fn store1(storage: &mut dyn Storage) -> Singleton<String> {
    singleton(storage, STORE1)
}

pub fn store1_read(storage: &dyn Storage) -> ReadonlySingleton<String> {
    singleton_read(storage, STORE1)
}

pub fn store2(storage: &mut dyn Storage) -> Singleton<String> {
    singleton(storage, STORE2)
}

pub fn store2_read(storage: &dyn Storage) -> ReadonlySingleton<String> {
    singleton_read(storage, STORE2)
}