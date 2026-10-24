export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      activities: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          start_at: string;
          end_at: string | null;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id: string;
          user_id: string;
          title: string;
          start_at: string;
          end_at?: string | null;
          updated_at: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          title?: string;
          start_at?: string;
          end_at?: string | null;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export type ActivityRow = Database["public"]["Tables"]["activities"]["Row"];
