#import <Flutter/Flutter.h>

@interface NekotonFlutterPlugin : NSObject<FlutterPlugin>
@end

// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

void nt_store_dart_post_cobject(void *ptr);

void *nt_cstring_to_void_ptr(char *ptr);

void nt_free_cstring(char *ptr);

void nt_accounts_storage_create(long long result_port, void *storage);

void nt_accounts_storage_entries(long long result_port, void *accounts_storage);

void nt_accounts_storage_add_account(long long result_port,
                                     void *accounts_storage,
                                     char *new_account);

void nt_accounts_storage_add_accounts(long long result_port,
                                      void *accounts_storage,
                                      char *new_accounts);

void nt_accounts_storage_rename_account(long long result_port,
                                        void *accounts_storage,
                                        char *account,
                                        char *name);

void nt_accounts_storage_add_token_wallet(long long result_port,
                                          void *accounts_storage,
                                          char *account,
                                          char *network_group,
                                          char *root_token_contract);

void nt_accounts_storage_remove_token_wallet(long long result_port,
                                             void *accounts_storage,
                                             char *account,
                                             char *network_group,
                                             char *root_token_contract);

void nt_accounts_storage_remove_account(long long result_port,
                                        void *accounts_storage,
                                        char *account);

void nt_accounts_storage_remove_accounts(long long result_port,
                                         void *accounts_storage,
                                         char *accounts);

void nt_accounts_storage_clear(long long result_port, void *accounts_storage);

void nt_accounts_storage_reload(long long result_port, void *accounts_storage);

char *nt_accounts_storage_verify_data(char *data);

void *nt_accounts_storage_clone_ptr(void *ptr);

void nt_accounts_storage_free_ptr(void *ptr);

void nt_generic_contract_subscribe(long long result_port,
                                   long long on_message_sent_port,
                                   long long on_message_expired_port,
                                   long long on_state_changed_port,
                                   long long on_transactions_found_port,
                                   void *transport,
                                   char *transport_type,
                                   char *address,
                                   unsigned int preload_transactions);

void nt_generic_contract_address(long long result_port, void *generic_contract);

void nt_generic_contract_contract_state(long long result_port, void *generic_contract);

void nt_generic_contract_pending_transactions(long long result_port, void *generic_contract);

void nt_generic_contract_polling_method(long long result_port, void *generic_contract);

void nt_generic_contract_estimate_fees(long long result_port,
                                       void *generic_contract,
                                       char *signed_message);

void nt_generic_contract_send(long long result_port, void *generic_contract, char *signed_message);

void nt_generic_contract_execute_transaction_locally(long long result_port,
                                                     void *generic_contract,
                                                     char *signed_message,
                                                     char *options);

void nt_generic_contract_refresh(long long result_port, void *generic_contract);

void nt_generic_contract_preload_transactions(long long result_port,
                                              void *generic_contract,
                                              char *from_lt);

void nt_generic_contract_handle_block(long long result_port, void *generic_contract, char *block);

void nt_generic_contract_free_ptr(void *ptr);

void nt_keystore_create(long long result_port, void *storage, void *connection, char *signers);

void nt_keystore_entries(long long result_port, void *keystore);

void nt_keystore_add_key(long long result_port, void *keystore, char *signer, char *input);

void nt_keystore_add_keys(long long result_port, void *keystore, char *signer, char *input);

void nt_keystore_update_key(long long result_port, void *keystore, char *signer, char *input);

void nt_keystore_export_key(long long result_port, void *keystore, char *signer, char *input);

void nt_keystore_get_public_keys(long long result_port, void *keystore, char *signer, char *input);

void nt_keystore_encrypt(long long result_port,
                         void *keystore,
                         char *signer,
                         char *data,
                         char *public_keys,
                         char *algorithm,
                         char *input);

void nt_keystore_decrypt(long long result_port,
                         void *keystore,
                         char *signer,
                         char *data,
                         char *input);

void nt_keystore_sign(long long result_port, void *keystore, char *signer, char *data, char *input, char *signature_id);

void nt_keystore_sign_data(long long result_port,
                           void *keystore,
                           char *signer,
                           char *data,
                           char *input,
                           char *signature_id);

void nt_keystore_sign_data_raw(long long result_port,
                               void *keystore,
                               char *signer,
                               char *data,
                               char *input,
                               char *signature_id);

void nt_transport_get_signature_id(long long result_port, void *transport, char *transport_type);

void nt_transport_get_network_id(long long result_port, void *transport, char *transport_type);

void nt_keystore_remove_key(long long result_port, void *keystore, char *public_key);

void nt_keystore_remove_keys(long long result_port, void *keystore, char *public_keys);

char *nt_keystore_is_password_cached(void *keystore, char *public_key, unsigned long long duration);

void nt_keystore_clear(long long result_port, void *keystore);

void nt_keystore_reload(long long result_port, void *keystore);

char *nt_keystore_verify_data(void *connection, char *signers, char *data);

void *nt_keystore_clone_ptr(void *ptr);

void nt_keystore_free_ptr(void *ptr);

void nt_token_wallet_subscribe(long long result_port,
                               long long on_balance_changed_port,
                               long long on_transactions_found_port,
                               void *transport,
                               char *transport_type,
                               char *owner,
                               char *root_token_contract);

void nt_token_wallet_owner(long long result_port, void *token_wallet);

void nt_token_wallet_address(long long result_port, void *token_wallet);

void nt_token_wallet_symbol(long long result_port, void *token_wallet);

void nt_token_wallet_version(long long result_port, void *token_wallet);

void nt_token_wallet_balance(long long result_port, void *token_wallet);

void nt_token_wallet_contract_state(long long result_port, void *token_wallet);

void nt_token_wallet_prepare_transfer(long long result_port,
                                      void *token_wallet,
                                      char *destination,
                                      char *tokens,
                                      unsigned int notify_receiver,
                                      char *payload);

void nt_token_wallet_refresh(long long result_port, void *token_wallet);

void nt_token_wallet_preload_transactions(long long result_port, void *token_wallet, char *from_lt);

void nt_token_wallet_handle_block(long long result_port, void *token_wallet, char *block);

void nt_get_token_root_details(long long result_port,
                               void *transport,
                               char *transport_type,
                               char *root_token_contract);

void nt_get_token_wallet_details(long long result_port,
                                 void *transport,
                                 char *transport_type,
                                 char *token_wallet);

void nt_get_token_root_details_from_token_wallet(long long result_port,
                                                 void *transport,
                                                 char *transport_type,
                                                 char *token_wallet_address);

void nt_token_wallet_free_ptr(void *ptr);

void nt_ton_wallet_subscribe(long long result_port,
                             long long on_message_sent_port,
                             long long on_message_expired_port,
                             long long on_state_changed_port,
                             long long on_transactions_found_port,
                             void *transport,
                             char *transport_type,
                             signed char workchain,
                             char *public_key,
                             char *contract);

void nt_ton_wallet_subscribe_by_address(long long result_port,
                                        long long on_message_sent_port,
                                        long long on_message_expired_port,
                                        long long on_state_changed_port,
                                        long long on_transactions_found_port,
                                        void *transport,
                                        char *transport_type,
                                        char *address);

void nt_ton_wallet_subscribe_by_existing(long long result_port,
                                         long long on_message_sent_port,
                                         long long on_message_expired_port,
                                         long long on_state_changed_port,
                                         long long on_transactions_found_port,
                                         void *transport,
                                         char *transport_type,
                                         char *existing_wallet);

void nt_ton_wallet_workchain(long long result_port, void *ton_wallet);

void nt_ton_wallet_address(long long result_port, void *ton_wallet);

void nt_ton_wallet_public_key(long long result_port, void *ton_wallet);

void nt_ton_wallet_wallet_type(long long result_port, void *ton_wallet);

void nt_ton_wallet_contract_state(long long result_port, void *ton_wallet);

void nt_ton_wallet_pending_transactions(long long result_port, void *ton_wallet);

void nt_ton_wallet_polling_method(long long result_port, void *ton_wallet);

void nt_ton_wallet_details(long long result_port, void *ton_wallet);

void nt_ton_wallet_unconfirmed_transactions(long long result_port, void *ton_wallet);

void nt_ton_wallet_custodians(long long result_port, void *ton_wallet);

void nt_ton_wallet_prepare_deploy(long long result_port, void *ton_wallet, char *expiration);

void nt_ton_wallet_prepare_deploy_with_multiple_owners(long long result_port,
                                                       void *ton_wallet,
                                                       char *expiration,
                                                       char *custodians,
                                                       unsigned char req_confirms);

void nt_ton_wallet_prepare_transfer(long long result_port,
                                    void *ton_wallet,
                                    char *contract_state,
                                    char *public_key,
                                    char *destination,
                                    char *amount,
                                    unsigned int bounce,
                                    char *body,
                                    char *expiration);

void nt_ton_wallet_prepare_confirm_transaction(long long result_port,
                                               void *ton_wallet,
                                               char *contract_state,
                                               char *public_key,
                                               char *transaction_id,
                                               char *expiration);

void nt_ton_wallet_estimate_fees(long long result_port, void *ton_wallet, char *signed_message);

void nt_ton_wallet_send(long long result_port, void *ton_wallet, char *signed_message);

void nt_ton_wallet_refresh(long long result_port, void *ton_wallet);

void nt_ton_wallet_preload_transactions(long long result_port, void *ton_wallet, char *from_lt);

void nt_ton_wallet_handle_block(long long result_port, void *ton_wallet, char *block);

void nt_find_existing_wallets(long long result_port,
                              void *transport,
                              char *transport_type,
                              char *public_key,
                              signed char workchain_id,
                              char *wallet_types);

void nt_get_existing_wallet_info(long long result_port,
                                 void *transport,
                                 char *transport_type,
                                 char *address);

void nt_get_wallet_custodians(long long result_port,
                              void *transport,
                              char *transport_type,
                              char *address);

void nt_ton_wallet_free_ptr(void *ptr);

void nt_unsigned_message_refresh_timeout(long long result_port, void *unsigned_message);

void nt_unsigned_message_expire_at(long long result_port, void *unsigned_message);

void nt_unsigned_message_hash(long long result_port, void *unsigned_message);

void nt_unsigned_message_sign(long long result_port, void *unsigned_message, char *signature);

void nt_unsigned_message_free_ptr(void *ptr);

char *nt_verify_signature(char *public_key, char *data_hash, char *signature);

char *nt_generate_key(char *mnemonic_type);

char *nt_get_hints(char *input);

char *nt_derive_from_phrase(char *phrase, char *mnemonic_type);

void nt_external_resolve_request_with_string(void *tx, char *ok, char *err);

void nt_external_resolve_request_with_optional_string(void *tx, char *ok, char *err);

void nt_external_resolve_request_with_unit(void *tx, char *err);

char *nt_gql_connection_create(unsigned int is_local, long long port);

void nt_gql_connection_free_ptr(void *ptr);

char *nt_jrpc_connection_create(long long port);

void nt_jrpc_connection_free_ptr(void *ptr);

char *nt_ledger_connection_create(long long get_public_key_port, long long sign_port);

void nt_ledger_connection_free_ptr(void *ptr);

char *nt_storage_create(long long get_port,
                        long long set_port,
                        long long set_unchecked_port,
                        long long remove_port,
                        long long remove_unchecked_port);

void nt_storage_free_ptr(void *ptr);

char *nt_pack_std_smc_addr(unsigned int base64_url, char *addr, unsigned int bounceable);

char *nt_unpack_std_smc_addr(char *packed, unsigned int base64_url);

char *nt_validate_address(char *address);

char *nt_repack_address(char *address);

char *nt_extract_public_key(char *boc);

char *nt_code_to_tvc(char *code);

char *nt_merge_tvc(char *code, char *data);

char *nt_split_tvc(char *tvc);

char *nt_set_code_salt(char *code, char *salt);

char *nt_get_code_salt(char *code);

char *nt_check_public_key(char *public_key);

char *nt_run_local(char *account_stuff_boc,
                   char *contract_abi,
                   char *method,
                   char *input,
                   unsigned int responsible);

char *nt_get_expected_address(char *tvc,
                              char *contract_abi,
                              signed char workchain_id,
                              char *public_key,
                              char *init_data);

char *nt_encode_internal_input(char *contract_abi, char *method, char *input);

char *nt_create_external_message_without_signature(char *dst,
                                                   char *contract_abi,
                                                   char *method,
                                                   char *state_init,
                                                   char *input,
                                                   unsigned int timeout);

char *nt_create_external_message(char *dst,
                                 char *contract_abi,
                                 char *method,
                                 char *state_init,
                                 char *input,
                                 char *public_key,
                                 unsigned int timeout);

char *nt_parse_known_payload(char *payload);

char *nt_decode_input(char *message_body, char *contract_abi, char *method, unsigned int internal);

char *nt_decode_event(char *message_body, char *contract_abi, char *event);

char *nt_decode_output(char *message_body, char *contract_abi, char *method);

char *nt_decode_transaction(char *transaction, char *contract_abi, char *method);

char *nt_decode_transaction_events(char *transaction, char *contract_abi);

char *nt_get_boc_hash(char *boc);

char *nt_pack_into_cell(char *params, char *tokens);

char *nt_unpack_from_cell(char *params, char *boc, unsigned int allow_partial);

void nt_transport_get_contract_state(long long result_port,
                                     void *transport,
                                     char *transport_type,
                                     char *address);

void nt_transport_get_full_contract_state(long long result_port,
                                          void *transport,
                                          char *transport_type,
                                          char *address);

void nt_transport_get_accounts_by_code_hash(long long result_port,
                                            void *transport,
                                            char *transport_type,
                                            char *code_hash,
                                            unsigned char limit,
                                            char *continuation);

void nt_transport_get_transactions(long long result_port,
                                   void *transport,
                                   char *transport_type,
                                   char *address,
                                   char *from_lt,
                                   unsigned char limit);

void nt_transport_get_transaction(long long result_port,
                                  void *transport,
                                  char *transport_type,
                                  char *hash);

char *nt_gql_transport_create(void *gql_connection);

void nt_gql_transport_get_latest_block_id(long long result_port,
                                          void *gql_transport,
                                          char *address);

void nt_gql_transport_get_block(long long result_port, void *gql_transport, char *id);

void nt_gql_transport_wait_for_next_block_id(long long result_port,
                                             void *gql_transport,
                                             char *current_block_id,
                                             char *address,
                                             unsigned long long timeout);

void nt_gql_transport_free_ptr(void *ptr);

char *nt_jrpc_transport_create(void *jrpc_connection);

void *nt_jrpc_transport_clone_ptr(void *ptr);

void nt_jrpc_transport_free_ptr(void *ptr);
