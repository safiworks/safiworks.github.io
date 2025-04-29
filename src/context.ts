//! Contains and fetches information from GitHub API
//!
//! fetches information like avatar url and full name from the GitHub API using the username
export const username = "safiworks";

export type UserContext = {
  full_name: string;
  username: string;
  avatar_url: string;
  profile_url: string;
};

const api_url = "https://api.github.com/users/";

export const ctx: UserContext = await fetch(api_url + username).then(
  async (response) => {
    if (!response.ok) {
      throw new Error("Failed to fetch user data");
    }

    return await response.json().then((data) => {
      return {
        full_name: data.name,
        username: data.login,
        avatar_url: data.avatar_url,
        profile_url: "https://github.com/" + data.login,
      };
    });
  },
);
