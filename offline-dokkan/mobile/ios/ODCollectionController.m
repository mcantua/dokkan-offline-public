#import "ODCollectionController.h"
@implementation ODCollectionController {
    NSMutableArray<NSDictionary *> *_characters;
    NSMutableArray<NSNumber *> *_members;
    NSInteger _slot;
    void (^_save)(NSArray<NSNumber *> *, void (^)(NSString *));
    BOOL _saving;
}
- (instancetype)initWithCharacters:(NSArray<NSDictionary *> *)characters selected:(NSArray<NSNumber *> *)selected teamSlot:(NSInteger)slot save:(void (^)(NSArray<NSNumber *> *, void (^)(NSString *)))save {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _characters = [characters mutableCopy]; _members = [selected mutableCopy] ?: [NSMutableArray array]; _slot = slot; _save = [save copy];
        self.title = slot < 0 ? @"Character List" : [NSString stringWithFormat:@"Team %ld", (long)slot + 1];
    } return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    if (_save) self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save team" style:UIBarButtonItemStyleDone target:self action:@selector(saveTeam)];
    [self updateSummary];
}
- (void)updateSummary {
    self.navigationItem.prompt = _slot < 0 ? [NSString stringWithFormat:@"%lu owned characters", (unsigned long)_characters.count] : [NSString stringWithFormat:@"%lu / 6 selected · First selected is the leader", (unsigned long)_members.count];
    if (!_characters.count) {
        UILabel *empty = [UILabel new]; empty.text = @"Your collection is empty. Finish a unit in Unit Creator to add it here.";
        empty.numberOfLines = 0; empty.textAlignment = NSTextAlignmentCenter; self.tableView.backgroundView = empty;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _characters.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"owned"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"owned"];
    NSDictionary *card = _characters[indexPath.row]; NSUInteger position = [_members indexOfObject:card[@"instance_id"]];
    cell.textLabel.text = card[@"name"]; cell.textLabel.numberOfLines = 0;
    NSString *member = position == NSNotFound ? @"" : position == 0 ? @" · Leader" : [NSString stringWithFormat:@" · Position %lu", (unsigned long)position + 1];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Lv %@ · Super Attack Lv %@%@%@", card[@"level"], card[@"sa_level"], [card[@"locked"] boolValue] ? @" · Locked" : @"", member];
    cell.detailTextLabel.numberOfLines = 0;
    cell.accessoryType = _slot >= 0 && position != NSNotFound ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; if (_saving) return;
    NSDictionary *card = _characters[indexPath.row];
    if (_slot < 0) {
        NSString *details = [NSString stringWithFormat:@"Lv %@\nSuper Attack Lv %@\n%@", card[@"level"], card[@"sa_level"], [card[@"locked"] boolValue] ? @"Locked" : @"Unlocked"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:card[@"name"] message:details preferredStyle:UIAlertControllerStyleAlert];
        if (self.lockCharacter) [alert addAction:[UIAlertAction actionWithTitle:[card[@"locked"] boolValue] ? @"Unlock character" : @"Lock character" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (self->_saving) return; self->_saving = YES;
            BOOL locked = ![card[@"locked"] boolValue];
            self.lockCharacter(card[@"instance_id"], locked, ^(NSString *error) {
                self->_saving = NO;
                if (!error) { NSMutableDictionary *updated = [card mutableCopy]; updated[@"locked"] = @(locked); self->_characters[indexPath.row] = updated; [self.tableView reloadData]; return; }
                UIAlertController *notice = [UIAlertController alertControllerWithTitle:@"Couldn't change the lock" message:@"Your collection may have changed. Close this screen and open it again." preferredStyle:UIAlertControllerStyleAlert];
                [notice addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:notice animated:YES completion:nil];
            });
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:alert animated:YES completion:nil]; return;
    }
    NSNumber *identity = card[@"instance_id"];
    if ([_members containsObject:identity]) [_members removeObject:identity];
    else if (_members.count < 6) [_members addObject:identity];
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Team is full" message:@"Choose up to 6 characters. Remove one before adding another." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:alert animated:YES completion:nil]; return;
    }
    [self updateSummary]; [tableView reloadData];
}
- (void)close { if (!_saving) [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)saveTeam {
    if (_saving || !_save) return; _saving = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO; self.navigationItem.leftBarButtonItem.enabled = NO;
    _save([_members copy], ^(NSString *error) {
        self->_saving = NO; self.navigationItem.rightBarButtonItem.enabled = YES; self.navigationItem.leftBarButtonItem.enabled = YES;
        if (!error) { [self dismissViewControllerAnimated:YES completion:nil]; return; }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Couldn't save the team" message:@"Your collection may have changed. Close this screen and choose your team again. Your previous team was kept." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]]; [self presentViewController:alert animated:YES completion:nil];
    });
}
@end
