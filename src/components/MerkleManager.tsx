import { useAsync, useAsyncFn } from "react-use";
import { TWITTER_ANON_SET } from "../helpers/constants";
import { Button } from "./Button";
import { D3Tree } from "./D3Tree";
import React, { useState, useEffect } from "react";
import styled from "styled-components";
import adjectiveNounGenerator from "adjective-noun-generator";
import { merkleTreeFromTwitterHandles } from "../helpers/twitterMerkle";
import Fuse from "fuse.js";

export type MerkleTreeList = {
  name: string;
  handles: string[];
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  align-items: top;
  width: 100%;
  height: 100%;
  row-gap: 1em;
`;

const ListContainer = styled.div`
  margin: 1em 0;
`;

const List = styled.ul`
  list-style-type: none;
`;

const ListItem = styled.li`
  margin: 0.5em 0;
  cursor: pointer;
`;

const NewListForm = styled.form`
  display: flex;
  flex-direction: column;
  width: 100%;
`;

const Input = styled.input`
  margin-bottom: 1em;
`;

const UserRow = styled.div`
  display: flex;
  flex-wrap: wrap;
`;

const User = styled.span`
  margin-right: 10px;
`;

const MerkleManager = ({
  twitterHandle,
  selectedList,
  onClose,
  onChange,
}: {
  twitterHandle: string;
  selectedList: MerkleTreeList | null;
  onClose: () => void;
  onChange: (userList: MerkleTreeList | null) => void;
}) => {
  const [newListName, setNewListName] = useState(adjectiveNounGenerator());
  const [newListUsers, setNewListUsers] = useState(() => {
    if (!twitterHandle) return "";
    return [...new Set([twitterHandle, ...TWITTER_ANON_SET])].sort().join(",");
  });

  const [search, setSearch] = useState("");

  const [merkleTrees, fetchMerkleTrees] = useAsyncFn<
    () => Promise<Record<string, MerkleTreeList>>
  >(async () => {
    try {
      if (!twitterHandle) return {};
      const response = await fetch("/api/merkle_trees?handle=" + twitterHandle);
      return response.json();
    } catch (e) {
      console.warn(e);
      return {};
    }
  }, [twitterHandle]);
  React.useEffect(() => {
    fetchMerkleTrees();
  }, [fetchMerkleTrees]);
  const userLists = React.useMemo(() => {
    if (!merkleTrees.value) return [];
    return Object.values(merkleTrees.value);
  }, [merkleTrees.value]);
  React.useEffect(() => {
    if (userLists.length === 0) return;
    if (!selectedList) return;
    if (!userLists.find((x) => x.name === selectedList.name && JSON.stringify(x.handles) === JSON.stringify(selectedList.handles))) {
      onChange(userLists[0]);
    }
  }, [userLists, selectedList, onChange]);
  const fuse = React.useMemo(
    () =>
      new Fuse(userLists, {
        keys: ["name", "handles"],
      }),
    [userLists]
  );

  const [, addMerkleTree] = useAsyncFn(async () => {
    try {
      const merkleTreeList = {
        name: newListName,
        handles: newListUsers
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean),
      };
      await fetch("/api/merkle_trees", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(merkleTreeList),
      });
    } catch (e) {
      console.warn(e);
      return {};
    }
  }, [newListName, newListUsers]);

  const { value: merkleTree } = useAsync(
    async () =>
      selectedList ? merkleTreeFromTwitterHandles(selectedList.handles) : null,
    [selectedList]
  );

  const filteredLists = React.useMemo(() => {
    if (!search) return userLists;
    return fuse.search(search).map((x) => x.item);
  }, [search, userLists, fuse]);

  return (
    <Container>
      {selectedList ? (
        <>
          <UserRow>
            {selectedList.handles.map((user) => (
              <User key={user}>{user}</User>
            ))}
          </UserRow>

          <div style={{ flex: 1 }}>
            {merkleTree && (
              <D3Tree
                data={merkleTree.toD3Data([
                  ...merkleTree
                    .getMerkleProof(twitterHandle)
                    .values.map((x) => x.toString()),
                  twitterHandle,
                ])}
                levels={merkleTree.levels}
              />
            )}
          </div>

          <Button
            onClick={() => {
              onChange(null);
            }}
          >
            Choose another list
          </Button>
        </>
      ) : (
        <>
          <div
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              rowGap: "4px",
            }}
          >
            <h2>Twitter user lists with your twitter handle</h2>
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search lists"
            />
            {filteredLists.map((list, i) => (
              <ListItem
                key={list.name + `__index__` + i}
                onClick={() => {
                  onChange(list);
                }}
              >
                {list.name}
              </ListItem>
            ))}
          </div>

          <NewListForm
            onSubmit={async (e) => {
              e.preventDefault();
              await addMerkleTree();
              await fetchMerkleTrees();
            }}
          >
            <h2>Create New List</h2>
            <Input
              value={newListName}
              onChange={(e) =>
                setNewListName(e.target.value.replace(/[^a-zA-Z0-9 ]/g, ""))
              }
              placeholder="Name your new list"
            />
            <Input
              value={newListUsers}
              onChange={(e) =>
                setNewListUsers(e.target.value.replace(/[^a-zA-Z0-9-_,]/g, ""))
              }
              placeholder="Enter usernames, separated by commas"
            />
            <Button type="submit">Create List</Button>
          </NewListForm>
        </>
      )}

      <Button onClick={onClose}>Confirm</Button>
    </Container>
  );
};

export default MerkleManager;
