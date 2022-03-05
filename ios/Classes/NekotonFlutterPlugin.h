#import <Flutter/Flutter.h>

@interface NekotonFlutterPlugin : NSObject <FlutterPlugin>
@end

void store_post_cobject(void *ptr);

void free_cstring(char *str);

void free_execution_result(void *ptr);

void *clone_unsigned_message_ptr(void *unsigned_message);

void free_unsigned_message_ptr(void *unsigned_message);

void create_accounts_storage(long long result_port, void *storage);

void *clone_accounts_storage_ptr(void *accounts_storage);

void free_accounts_storage_ptr(void *accounts_storage);

void get_accounts(long long result_port, void *accounts_storage);

void add_account(long long result_port,
                 void *accounts_storage,
                 char *name,
                 char *public_key,
                 char *contract,
                 signed char workchain);

void rename_account(long long result_port, void *accounts_storage, char *address, char *name);

void remove_account(long long result_port, void *accounts_storage, char *address);

void add_token_wallet(long long result_port,
                      void *accounts_storage,
                      char *address,
                      char *network_group,
                      char *root_token_contract);

void remove_token_wallet(long long result_port,
                         void *accounts_storage,
                         char *address,
                         char *network_group,
                         char *root_token_contract);

void clear_accounts_storage(long long result_port, void *accounts_storage);

void generic_contract_subscribe(long long result_port,
                                long long on_message_sent_port,
                                long long on_message_expired_port,
                                long long on_state_changed_port,
                                long long on_transactions_found_port,
                                void *transport,
                                int transport_type,
                                char *address);

void *clone_generic_contract_ptr(void *generic_contract);

void free_generic_contract_ptr(void *generic_contract);

void get_generic_contract_address(long long result_port, void *generic_contract);

void get_generic_contract_contract_state(long long result_port, void *generic_contract);

void get_generic_contract_pending_transactions(long long result_port, void *generic_contract);

void get_generic_contract_polling_method(long long result_port, void *generic_contract);

void generic_contract_estimate_fees(long long result_port, void *generic_contract, void *message);

void generic_contract_send(long long result_port,
                           void *generic_contract,
                           void *keystore,
                           void *message,
                           char *sign_input);

void generic_contract_execute_transaction_locally(long long result_port,
                                                  void *generic_contract,
                                                  void *keystore,
                                                  void *message,
                                                  char *sign_input,
                                                  char *options);

void generic_contract_refresh(long long result_port, void *generic_contract);

void generic_contract_preload_transactions(long long result_port,
                                           void *generic_contract,
                                           char *from);

void generic_contract_handle_block(long long result_port,
                                   void *generic_contract,
                                   void *transport,
                                   int transport_type,
                                   char *id);

void create_keystore(long long result_port, void *storage);

void *clone_keystore_ptr(void *keystore);

void free_keystore_ptr(void *keystore);

void get_entries(long long result_port, void *keystore);

void add_key(long long result_port, void *keystore, char *create_key_input);

void update_key(long long result_port, void *keystore, char *update_key_input);

void export_key(long long result_port, void *keystore, char *export_key_input);

void check_key_password(long long result_port, void *keystore, char *sign_input);

void remove_key(long long result_port, void *keystore, char *public_key);

void clear_keystore(long long result_port, void *keystore);

void token_wallet_subscribe(long long result_port,
                            long long on_balance_changed_port,
                            long long on_transactions_found_port,
                            void *transport,
                            int transport_type,
                            char *owner,
                            char *root_token_contract);

void *clone_token_wallet_ptr(void *token_wallet);

void free_token_wallet_ptr(void *token_wallet);

void get_token_wallet_owner(long long result_port, void *token_wallet);

void get_token_wallet_address(long long result_port, void *token_wallet);

void get_token_wallet_symbol(long long result_port, void *token_wallet);

void get_token_wallet_version(long long result_port, void *token_wallet);

void get_token_wallet_balance(long long result_port, void *token_wallet);

void get_token_wallet_contract_state(long long result_port, void *token_wallet);

void token_wallet_prepare_transfer(long long result_port,
                                   void *token_wallet,
                                   char *destination,
                                   char *tokens,
                                   unsigned int notify_receiver,
                                   char *payload);

void token_wallet_refresh(long long result_port, void *token_wallet);

void token_wallet_preload_transactions(long long result_port, void *token_wallet, char *from);

void get_token_root_details(long long result_port,
                            void *transport,
                            int transport_type,
                            char *root_token_contract);

void get_token_wallet_details(long long result_port,
                              void *transport,
                              int transport_type,
                              char *token_wallet);

void get_token_root_details_from_token_wallet(long long result_port,
                                              void *transport,
                                              int transport_type,
                                              char *token_wallet_address);

void ton_wallet_subscribe(long long result_port,
                          long long on_message_sent_port,
                          long long on_message_expired_port,
                          long long on_state_changed_port,
                          long long on_transactions_found_port,
                          void *transport,
                          int transport_type,
                          signed char workchain,
                          char *public_key,
                          char *contract);

void ton_wallet_subscribe_by_address(long long result_port,
                                     long long on_message_sent_port,
                                     long long on_message_expired_port,
                                     long long on_state_changed_port,
                                     long long on_transactions_found_port,
                                     void *transport,
                                     int transport_type,
                                     char *address);

void ton_wallet_subscribe_by_existing(long long result_port,
                                      long long on_message_sent_port,
                                      long long on_message_expired_port,
                                      long long on_state_changed_port,
                                      long long on_transactions_found_port,
                                      void *transport,
                                      int transport_type,
                                      char *existing_wallet);

void *clone_ton_wallet_ptr(void *ton_wallet);

void free_ton_wallet_ptr(void *ton_wallet);

void get_ton_wallet_workchain(long long result_port, void *ton_wallet);

void get_ton_wallet_address(long long result_port, void *ton_wallet);

void get_ton_wallet_public_key(long long result_port, void *ton_wallet);

void get_ton_wallet_wallet_type(long long result_port, void *ton_wallet);

void get_ton_wallet_contract_state(long long result_port, void *ton_wallet);

void get_ton_wallet_pending_transactions(long long result_port, void *ton_wallet);

void get_ton_wallet_polling_method(long long result_port, void *ton_wallet);

void get_ton_wallet_details(long long result_port, void *ton_wallet);

void get_ton_wallet_unconfirmed_transactions(long long result_port, void *ton_wallet);

void get_ton_wallet_custodians(long long result_port, void *ton_wallet);

void ton_wallet_prepare_deploy(long long result_port, void *ton_wallet, char *expiration);

void ton_wallet_prepare_deploy_with_multiple_owners(long long result_port,
                                                    void *ton_wallet,
                                                    char *expiration,
                                                    char *custodians,
                                                    unsigned char req_confirms);

void ton_wallet_prepare_transfer(long long result_port,
                                 void *ton_wallet,
                                 void *transport,
                                 int transport_type,
                                 char *public_key,
                                 char *destination,
                                 char *amount,
                                 char *body,
                                 char *expiration);

void ton_wallet_prepare_confirm_transaction(long long result_port,
                                            void *ton_wallet,
                                            void *transport,
                                            int transport_type,
                                            char *public_key,
                                            char *transaction_id,
                                            char *expiration);

void ton_wallet_estimate_fees(long long result_port, void *ton_wallet, void *message);

void ton_wallet_send(long long result_port,
                     void *ton_wallet,
                     void *keystore,
                     void *message,
                     char *sign_input);

void ton_wallet_refresh(long long result_port, void *ton_wallet);

void ton_wallet_preload_transactions(long long result_port, void *ton_wallet, char *from);

void ton_wallet_handle_block(long long result_port,
                             void *ton_wallet,
                             void *transport,
                             int transport_type,
                             char *id);

void find_existing_wallets(long long result_port,
                           void *transport,
                           int transport_type,
                           char *public_key,
                           signed char workchain_id);

void get_existing_wallet_info(long long result_port,
                              void *transport,
                              int transport_type,
                              char *address);

void get_wallet_custodians(long long result_port,
                           void *transport,
                           int transport_type,
                           char *address);

void *generate_key(char *mnemonic_type);

void *get_hints(char *input);

void *derive_from_phrase(char *phrase, char *mnemonic_type);

void *create_storage(char *dir);

void *clone_storage_ptr(void *storage);

void free_storage_ptr(void *storage);

void get_full_account_state(long long result_port,
                            void *transport,
                            int transport_type,
                            char *address);

void get_transactions(long long result_port,
                      void *transport,
                      int transport_type,
                      char *address,
                      char *continuation,
                      unsigned char limit);

void *create_gql_transport(char *settings);

void *clone_gql_transport_ptr(void *gql_transport);

void free_gql_transport_ptr(void *gql_transport);

void get_latest_block_id(long long result_port, void *gql_transport, char *address);

void wait_for_next_block_id(long long result_port,
                            void *gql_transport,
                            char *current_block_id,
                            char *address,
                            unsigned long long timeout);

void *create_jrpc_transport(char *endpoint);

void *clone_jrpc_transport_ptr(void *jrpc_transport);

void free_jrpc_transport_ptr(void *jrpc_transport);

void *pack_std_smc_addr(unsigned int base64_url, char *addr, unsigned int bounceable);

void *unpack_std_smc_addr(char *packed, unsigned int base64_url);

void *validate_address(char *address);

void *repack_address(char *address);

void *run_local(char *account_stuff_boc, char *contract_abi, char *method, char *input);

void *get_expected_address(char *tvc,
                           char *contract_abi,
                           signed char workchain_id,
                           char *public_key,
                           char *init_data);

void *pack_into_cell(char *params, char *tokens);

void *unpack_from_cell(char *params, char *boc, unsigned int allow_partial);

void *extract_public_key(char *boc);

void *code_to_tvc(char *code);

void *split_tvc(char *tvc);

void *encode_internal_input(char *contract_abi, char *method, char *input);

void *decode_input(char *message_body, char *contract_abi, char *method, unsigned int internal);

void *decode_output(char *message_body, char *contract_abi, char *method);

void *decode_event(char *message_body, char *contract_abi, char *event);

void *decode_transaction(char *transaction, char *contract_abi, char *method);

void *decode_transaction_events(char *transaction, char *contract_abi);

void *parse_known_payload(char *payload);

void *create_external_message(char *dst,
                              char *contract_abi,
                              char *method,
                              char *state_init,
                              char *input,
                              char *public_key,
                              unsigned int timeout);
