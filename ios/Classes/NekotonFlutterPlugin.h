#import <Flutter/Flutter.h>

@interface NekotonFlutterPlugin : NSObject<FlutterPlugin>
@end

void store_post_cobject(void *ptr);

void free_cstring(char *str);

void free_native_result(void *ptr);

void get_accounts_storage(long long result_port, void *storage);

void get_accounts(long long result_port, void *accounts_storage);

void add_account(long long result_port,
                 void *accounts_storage,
                 char *name,
                 char *public_key,
                 char *contract);

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

void get_keystore(long long result_port, void *storage);

void get_entries(long long result_port, void *keystore);

void add_key(long long result_port, void *keystore, char *create_key_input);

void update_key(long long result_port, void *keystore, char *update_key_input);

void export_key(long long result_port, void *keystore, char *export_key_input);

void check_key_password(long long result_port, void *keystore, char *sign_input);

void remove_key(long long result_port, void *keystore, char *public_key);

void clear_keystore(long long result_port, void *keystore);

void token_wallet_subscribe(long long result_port,
                            long long port,
                            void *transport,
                            char *owner,
                            char *root_token_contract);

void get_token_wallet_owner(long long result_port, void *token_wallet);

void get_token_wallet_address(long long result_port, void *token_wallet);

void get_token_wallet_symbol(long long result_port, void *token_wallet);

void get_token_wallet_version(long long result_port, void *token_wallet);

void get_token_wallet_balance(long long result_port, void *token_wallet);

void get_token_wallet_contract_state(long long result_port, void *token_wallet);

void token_wallet_prepare_deploy(long long result_port,
                                 void *token_wallet,
                                 void *ton_wallet,
                                 void *transport,
                                 char *expiration);

void token_wallet_prepare_transfer(long long result_port,
                                   void *token_wallet,
                                   void *ton_wallet,
                                   void *transport,
                                   char *expiration,
                                   char *destination,
                                   char *tokens,
                                   unsigned int notify_receiver);

void token_wallet_refresh(long long result_port, void *token_wallet);

void token_wallet_preload_transactions(long long result_port, void *token_wallet, char *from);

void token_wallet_handle_block(long long result_port,
                               void *token_wallet,
                               void *transport,
                               char *id);

void token_wallet_unsubscribe(long long result_port, void *token_wallet);

void ton_wallet_subscribe(long long result_port,
                          long long port,
                          void *transport,
                          char *public_key,
                          char *contract);

void ton_wallet_subscribe_by_address(long long result_port,
                                     long long port,
                                     void *transport,
                                     char *address);

void ton_wallet_subscribe_by_existing(long long result_port,
                                      long long port,
                                      void *transport,
                                      char *existing_wallet);

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
                                 char *expiration,
                                 char *destination,
                                 unsigned long long amount,
                                 char *body);

void ton_wallet_prepare_confirm_transaction(long long result_port,
                                            void *ton_wallet,
                                            void *transport,
                                            unsigned long long transaction_id,
                                            char *expiration);

void prepare_add_ordinary_stake(long long result_port,
                                void *ton_wallet,
                                void *transport,
                                char *expiration,
                                char *depool,
                                unsigned long long depool_fee,
                                unsigned long long stake);

void prepare_withdraw_part(long long result_port,
                           void *ton_wallet,
                           void *transport,
                           char *expiration,
                           char *depool,
                           unsigned long long depool_fee,
                           unsigned long long withdraw_value);

void ton_wallet_estimate_fees(long long result_port, void *ton_wallet, void *message);

void ton_wallet_send(long long result_port,
                     void *ton_wallet,
                     void *keystore,
                     void *message,
                     char *sign_input);

void ton_wallet_refresh(long long result_port, void *ton_wallet);

void ton_wallet_preload_transactions(long long result_port, void *ton_wallet, char *from);

void ton_wallet_handle_block(long long result_port, void *ton_wallet, void *transport, char *id);

void ton_wallet_unsubscribe(long long result_port, void *ton_wallet);

void find_existing_wallets(long long result_port,
                           void *transport,
                           char *public_key,
                           int workchain_id);

void *generate_key(char *mnemonic_type);

void *get_hints(char *input);

void *derive_from_phrase(char *phrase, char *mnemonic_type);

void get_participant_info(long long result_port,
                          void *transport,
                          char *address,
                          char *wallet_address);

void get_depool_info(long long result_port, void *transport, char *address);

void *get_storage(long long port);

void *get_gql_connection(long long port);

void resolve_gql_request(void *tx, unsigned int is_successful, char *value);

void resolve_storage_request(void *tx, unsigned int is_successful, char *value);

void *pack_std_smc_addr(unsigned int base64_url, char *addr, unsigned int bounceable);

void *unpack_std_smc_addr(char *packed, unsigned int base64_url);

void *validate_address(char *address);

void *repack_address(char *address);

void *parse_message_body_data(char *data);

void get_gql_transport(long long result_port, void *connection);

void get_latest_block_id(long long result_port, void *transport, char *address);

void wait_for_next_block_id(long long result_port,
                            void *transport,
                            char *current_block_id,
                            char *address);
