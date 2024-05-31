import { createColumnHelper } from "@tanstack/solid-table";

export interface CaseData {
  target_id: string;
  target_tag: string;
  cases_count: number;
}

const columnHelper = createColumnHelper<CaseData>();

export const columns = (guildId: string) => [
  columnHelper.accessor("target_id", {
    header: "Target id",
    cell(info) {
      return (
        <a
          class="decoration-blue-500 underline"
          href={`/guilds/${guildId}/moderation/cases/${info.getValue()}`}
        >
          {info.getValue()}
        </a>
      );
    },
  }),
  columnHelper.accessor("target_tag", {
    header: "Username",
    cell: (i) => i.getValue(),
  }),
  columnHelper.accessor("cases_count", {
    header: "Cases",
    cell: (i) => i.getValue(),
  }),
];
