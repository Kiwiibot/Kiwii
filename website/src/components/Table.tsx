import {
  createSolidTable,
  getCoreRowModel,
  flexRender,
  type ColumnDef,
} from "@tanstack/solid-table";

export function Table({
  columns,
  data,
}: {
  readonly columns: ColumnDef<any, any>[];
  readonly data: any;
}) {
  const table = createSolidTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div class="p-4">
      <table class="w-full">
        <thead>
          {table.getHeaderGroups().map((headerGroup) => (
            <tr>
              {headerGroup.headers.map((header) => (
                <th class="dark:bg-gray-800 bg-gray-200 p-4 text-left first:rounded-l-lg last:rounded-r-lg">
                  {header.isPlaceholder
                    ? null
                    : flexRender(
                        header.column.columnDef.header,
                        header.getContext()
                      )}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody>
          {table.getRowModel().rows.map((row) => (
            <tr class="hover:dark:bg-gray-400 hover:bg-gray-700">
              {row.getVisibleCells().map((cell) => (
                <td class="px-4 py-2 first:rounded-l-lg last:rounded-r-lg">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
        <tfoot>
          {table.getFooterGroups().map((footerGroup) => (
            <tr>
              {footerGroup.headers.map((header) => (
                <th>
                  {header.isPlaceholder
                    ? null
                    : flexRender(
                        header.column.columnDef.footer,
                        header.getContext()
                      )}
                </th>
              ))}
            </tr>
          ))}
        </tfoot>
      </table>
    </div>
  );
}
