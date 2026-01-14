module my_addr::pet_registry {
    use std::signer;
    use std::vector;
    use std::string::{String};

    ///Chưa khởi tạo PetList
    const E_NOT_INITIALIZED: u64 = 1;
    ///Đã khởi tạo PetList
    const E_ALREADY_INITIALIZED: u64 = 2;

    struct Pet has store, drop{
        name: String,
        age: u8,
        species: String
    }

    struct PetList has key {
        pets:  vector<Pet>
    }

    public entry fun init_list(user: &signer) {
        assert!(exists<PetList>(signer::address_of(user)), E_ALREADY_INITIALIZED);
        move_to(user, PetList {
            pets: vector::empty(),
        })
    }

    public entry fun add_pet(user: &signer, name: String, age: u8, species: String) acquires PetList {
        let user_addr = signer::address_of(user);
        assert!(exists<PetList>(user_addr), E_NOT_INITIALIZED);
        let pet_list = borrow_global_mut<PetList>(user_addr);
        pet_list.pets.push_back(Pet{name, age, species});
    }
}