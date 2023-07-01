{ ... }:
let initialHashedPassword = "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in {
  users.users.root = {
    inherit initialHashedPassword;
  };

  teevik.user.extraOptions = {
    inherit initialHashedPassword;
  };
}
